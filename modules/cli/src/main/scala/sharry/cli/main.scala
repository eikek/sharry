package sharry.cli

import java.nio.channels.AsynchronousChannelGroup
import java.util.concurrent.{Executors, CountDownLatch, TimeUnit}
import org.slf4j.LoggerFactory
import org.log4s._
import ch.qos.logback.classic.LoggerContext
import ch.qos.logback.classic.joran.JoranConfigurator
import ch.qos.logback.core.util.StatusPrinter

import fs2.{Sink, Strategy, Stream, Scheduler, Task}
import sharry.cli.config._

object main extends maincmds {
  val ES = Executors.newCachedThreadPool(Strategy.daemonThreadFactory("sharry-cli-ACG"))
  implicit val ACG = AsynchronousChannelGroup.withThreadPool(ES) // http.client requires a group
  implicit val S = Strategy.fromExecutor(ES) // Async (Task) requires a strategy
  implicit val SCH = Scheduler.fromFixedDaemonPool(5, "sharry-cookie-refresh")

  private val parseError = ClientError("Invalid arguments.")

  def parse(args: Array[String], default: Config): Task[Config] =
    parser.optionParser.parse(args, default) match {
      case Some(cfg) => Task.now(cfg)
      case None => Task.fail(parseError)
    }

  def execute(cfg: Config): Task[Unit] = {
    val latch = new CountDownLatch(1) // a poor approach to ensure last progress event (all cmds must have a `done' at the end!)
    val stdout: Sink[Task, Progress] = new StdoutSink(cfg, latch)
    val task = cfg.mode match {
      case Mode.UploadFiles => upload
      case Mode.PublishFiles => publish
      case Mode.Resume(abort) =>
        if (abort) resumeAbort else resumeContinue
      case Mode.MdPublish => mdPublish
      case Mode.MdUpload => mdUpload
      case Mode.Manual(html) => cmds.manual(html)
    }
    (Cmd.eval(task, cfg, stdout) ++ Stream.eval(Task.delay(latch.await(2, TimeUnit.SECONDS))).drain).run
  }

  def setupLogging(cfg: Config): Task[Unit] = Task.delay {
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

    program.attempt.unsafeRun match {
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
