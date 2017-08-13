package sharry.cli

import java.util.concurrent.atomic.AtomicReference

import scala.sys.process._
import fs2.Task
import org.log4s._

object OS {

  private final val logger = getLogger

  def command(cmd: String): Task[SysCmd] = {
    // todo more robust splitting
    logger.trace(s"Creating system command from string '$cmd'")
    cmd.split("\\s+").toList match {
      case a :: as => Task.now(SysCmd(a, as))
      case _ => Task.fail(ClientError(s"Invalid command: $cmd"))
    }
  }

  case class SysCmd(program: String, args: Seq[String]) {
    def runFirstLine: Task[String] = {
      logger.debug(s"Running to first output line of command: $this")
      val line = new AtomicReference[String]()
      val stderr = collection.mutable.ListBuffer.empty[String]
      val appendErr: String => Unit = { s =>
        logger.trace(s"StdErr ($this): $s")
        if (stderr.size < 500) stderr += s
        else ()
      }
      checkRc(stderr)(Process(program +: args) !< ProcessLogger(line.compareAndSet(null, _), appendErr)).
        map { _ =>
          logger.trace(s"$this: output line: '${line.get}'")
          line.get
        }
    }

    private def checkRc(stderr: collection.mutable.ListBuffer[String])(rc: => Int): Task[Unit] =
      Task.delay(rc).
        handleWith({case e =>
          logger.error(e)("Exception when executing system command")
          Task.fail(ClientError.fromThrowable(e))
        }).
        flatMap {
          case 0 => Task.now(())
          case n =>
            logger.error(s"System command returned with code $n")
            Task.fail(ClientError(s"Non-zero exit code: $n", stderr.toSeq: _*))
        }
  }
}
