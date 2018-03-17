package sharry.server

import java.time.Instant
import java.net.InetSocketAddress
import java.util.concurrent.{Executors, ThreadFactory}
import java.util.concurrent.atomic.AtomicLong
import java.nio.file.{Path, Paths}
import java.nio.channels.AsynchronousChannelGroup
import scala.concurrent.ExecutionContext
import scala.concurrent.duration._

import fs2._
import cats.effect.IO
import cats.implicits._
import scodec.{Attempt, Codec}
import spinoco.fs2.http
import spinoco.fs2.http.HttpResponse
import spinoco.fs2.http.body.BodyEncoder
import spinoco.fs2.http.routing._
import spinoco.protocol.http.HttpRequestHeader
import spinoco.protocol.http.HttpStatusCode
import spinoco.protocol.http.codec.HttpRequestHeaderCodec

import org.log4s._

import sharry.common.BuildInfo
import sharry.common.file._
import sharry.common.streams
import sharry.common.version
import sharry.store.evolution
import sharry.server.codec.HttpHeaderCodec

object main {
  implicit val logger = getLogger

  def main(args: Array[String]): Unit = {

    implicit val EC = ExecutionContext.fromExecutorService(Executors.newCachedThreadPool(new ThreadFactory() {
      private val counter = new AtomicLong(0)
      def newThread(r: Runnable) =
        new Thread(r, s"sharry-${counter.getAndIncrement}")
    }))
    implicit val ACG = AsynchronousChannelGroup.withThreadPool(EC) // http.server requires a group
    val EC2 = Executors.newScheduledThreadPool(5)
    implicit val SCH = Scheduler.fromScheduledExecutorService(EC2)

    logger.info(s"""
       |––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
       | Sharry ${version.longVersion} build at ${BuildInfo.builtAtString.dropRight(4)}UTC is starting up …
       |––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––""".stripMargin)
    val startupCfg = StartConfig.parse(args)
    startupCfg.setup.unsafeRunSync
    val app = new App(config.Config.default)

    logger.info("""
       |––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
       | • Running initialize tasks …
       |––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––""".stripMargin)
    evolution(app.cfg.jdbc.url).runChanges(app.jdbc).unsafeRunSync
    async.start(startCleanup(app)).unsafeRunSync

    val shutdown =
      for {
        _   <- IO(logger.info("Closing database"))
        _   <- IO(app.jdbc.kernel.close())
        _   <- IO(logger.info("Closing threadpools"))
        _   <- IO(EC2.shutdown())
        _   <- IO(EC.shutdown())
      } yield ()

    val server = http.server[IO](
      bindTo = new InetSocketAddress(app.cfg.webConfig.bindHost, app.cfg.webConfig.bindPort),
      requestCodec = requestHeaderCodec,
      requestHeaderReceiveTimeout = 10.seconds,
      sendFailure = handleSendFailure _, // (Option[HttpRequestHeader], HttpResponse[F], Throwable) => Stream[F, Nothing],
      requestFailure = logRequestErrors _)(route(app.endpoints)).
      onFinalize(shutdown)

    logger.info(s"""
       |––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
       | • Starting http server at ${app.cfg.webConfig.bindHost}:${app.cfg.webConfig.bindPort}
       |––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––""".stripMargin)

    if (startupCfg.console) {
      startWithConsole(server).unsafeRunSync
    } else {
      server.compile.drain.unsafeRunSync
    }
  }


  private def startWithConsole(server: Stream[IO,Unit]): IO[Unit] = {
    implicit val ec = ExecutionContext.Implicits.global
    async.signalOf[IO, Boolean](false).flatMap ({ interrupt =>
      for {
        wait1 <- async.start(server.interruptWhen(interrupt).compile.drain)
        _ <- IO(println("Hit RETURN to stop the server"))
        _ <- IO(scala.io.StdIn.readLine())
        _ <- interrupt.set(true)
        _ <- wait1
        _ <- IO(logger.info("Sharry has stopped"))
      } yield ()
    })
  }

  private def startCleanup(app: App)(implicit SCH: Scheduler, EC: ExecutionContext): IO[Unit] = {
    val cfg = app.uploadConfig
    if (cfg.cleanupEnable) {
      logger.info(s"Scheduling cleanup job every ${cfg.cleanupInterval}")
      val stream = SCH.awakeEvery[IO](cfg.cleanupInterval.asScala).
        flatMap({ _ =>
          logger.info("Running cleanup job")
          val since = Instant.now.minus(cfg.cleanupInvalidAge.asJava)
          app.uploadStore.cleanup(since).
            through(streams.ifEmpty(Stream.emit(0))).fold1(_ + _).
            evalMap(n => IO(logger.info(s"Cleanup job removed $n uploads"))) ++
            Stream.eval(IO(logger.info("Cleanup job done."))).drain
        })

      stream.compile.drain
    } else {
      logger.info("Not starting cleanup job as requested")
      IO.pure(())
    }
  }

  private def logRequestErrors[F[_]](error: Throwable): Stream[F, HttpResponse[F]] = Stream.suspend {
    implicit val enc = BodyEncoder.utf8String
    logger.error(error)("Error in request")
    Stream.emit(HttpResponse[F](HttpStatusCode.InternalServerError).withBody(error.getClass + ":" + error.getMessage)).covary[F]
  }

  private def handleSendFailure[F[_]](header: Option[HttpRequestHeader], response: HttpResponse[F], err:Throwable): Stream[F, Nothing] = {
    Stream.suspend {
      err match {
        case _: java.io.IOException if err.getMessage == "Broken pipe" || err.getMessage == "Connection reset by peer" =>
          logger.warn(s"Error sending response: ${err.getMessage}! Request headers: ${header}")
        case _ =>
          logger.error(err)(s"Error sending response! Request headers: ${header}")
      }
      Stream.empty
    }
  }

  private def requestHeaderCodec: Codec[HttpRequestHeader] = {
    val codec = HttpRequestHeaderCodec.codec(HttpHeaderCodec.codec(Int.MaxValue))
    Codec (
      h => codec.encode(h),
      v => codec.decode(v) match {
        case a: Attempt.Successful[_] => a
        case f@ Attempt.Failure(cause) =>
          logger.error(s"Error parsing request ${v.decodeUtf8} \n$cause")
          f
      }
    )
  }

  case class StartConfig(console: Boolean, configFile: Option[Path]) {
    def setup: IO[Unit] = IO {
      configFile.foreach { f =>
        logger.info(s"Using config file $f")
        System.setProperty("config.file", f.toString)
      }
    }
  }

  object StartConfig {

    def parse(args: Seq[String]): StartConfig = {
      val console = {
        args.exists(_ == "--console") ||
        Option(System.getProperty("sharry.console")).
          exists(_ equalsIgnoreCase "true")
      }

      val file = args.find(_ != "--console").
        map(f => Paths.get(f)).
        orElse {
          Option(System.getProperty("sharry.optionalConfig")).
            map(f => Paths.get(f)).
            filter(_.exists)
        }

      StartConfig(console, file)
    }
  }
}
