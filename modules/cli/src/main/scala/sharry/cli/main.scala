package sharry.cli

import java.nio.channels.AsynchronousChannelGroup
import java.util.concurrent.{Executors, CountDownLatch, TimeUnit, ThreadFactory}
import java.util.concurrent.atomic.AtomicLong
import org.slf4j.LoggerFactory
import org.log4s._
import ch.qos.logback.classic.LoggerContext
import ch.qos.logback.classic.joran.JoranConfigurator
import ch.qos.logback.core.util.StatusPrinter

import fs2.{Sink, Stream, Scheduler}
import cats.effect.IO
import sharry.cli.config._
import scala.concurrent.ExecutionContext

object main extends maincmds {
  implicit val EC = ExecutionContext.fromExecutorService(Executors.newCachedThreadPool(new ThreadFactory() {
    private val counter = new AtomicLong(0)
    def newThread(r: Runnable) =
      new Thread(r, s"sharry-${counter.getAndIncrement}")
  }))
  implicit val ACG = AsynchronousChannelGroup.withThreadPool(EC) // http.server requires a group
  implicit val SCH = Scheduler.fromScheduledExecutorService(Executors.newScheduledThreadPool(5))

  private val parseError = ClientError("Invalid arguments.")

  def parse(args: Array[String], default: Config): IO[Config] =
    parser.optionParser.parse(args, default) match {
      case Some(cfg) => IO.pure(cfg)
      case None => IO.raiseError(parseError)
    }

  def execute(cfg: Config): IO[Unit] = {
    val latch = new CountDownLatch(1) // a poor approach to ensure last progress event (all cmds must have a `done' at the end!)
    val stdout: Sink[IO, Progress] = new StdoutSink(cfg, latch)
    val task = cfg.mode match {
      case Mode.UploadFiles => upload
      case Mode.PublishFiles => publish
      case Mode.Resume(abort) =>
        if (abort) resumeAbort else resumeContinue
      case Mode.MdPublish => mdPublish
      case Mode.MdUpload => mdUpload
      case Mode.Manual(html) => cmds.manual(html)
    }
    (Cmd.eval(task, cfg, stdout) ++ Stream.eval(IO(latch.await(2, TimeUnit.SECONDS))).drain).compile.drain
  }

  def setupLogging(cfg: Config): IO[Unit] = IO {
    val context = LoggerFactory.getILoggerFactory.asInstanceOf[LoggerContext]
    val config = new JoranConfigurator()
    config.setContext(context)
    context.reset()
    context.putProperty("sharry.loglevel", cfg.loglevel)
    config.doConfigure(getClass.getResource("/logback.xml"))
    StatusPrinter.printInCaseOfErrorsOrWarnings(context)
  }

  def main(args: Array[String]): Unit = {
    val program = for {
      zeroCfg <- parse(args, Config.empty) // only parse for getting the config file
      defaultCfg <- Config.loadDefaultConfig(zeroCfg.source)
      cfg <- parse(args, defaultCfg)
      _ <- setupLogging(cfg)
      _ <- execute(cfg)
    } yield ()

    program.attempt.unsafeRunSync match {
      case Right(_) =>
        Console.flush()
        System.exit(0)
      case Left(ex) =>
        if (ex != parseError) {
          getLogger.error(ex)(s"Error running command: ${args.mkString(" ")}")
          Console.err.println(StdoutSink.formatError(ex))
          Console.flush()
        }
        System.exit(1)
    }
  }
}
