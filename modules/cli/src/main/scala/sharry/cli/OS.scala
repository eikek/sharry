package sharry.cli

import java.util.concurrent.atomic.AtomicReference

import scala.sys.process._
import cats.effect.IO
import cats.implicits._
import org.log4s._

object OS {

  private final val logger = getLogger

  def command(cmd: String): IO[SysCmd] = {
    // todo more robust splitting
    logger.trace(s"Creating system command from string '$cmd'")
    cmd.split("\\s+").toList match {
      case a :: as => IO.pure(SysCmd(a, as))
      case _ => IO.raiseError(ClientError(s"Invalid command: $cmd"))
    }
  }

  case class SysCmd(program: String, args: Seq[String]) {
    def runFirstLine: IO[String] = {
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

    private def checkRc(stderr: collection.mutable.ListBuffer[String])(rc: => Int): IO[Unit] =
      IO(rc).
        handleErrorWith({case e =>
          logger.error(e)("Exception when executing system command")
          IO.raiseError(ClientError.fromThrowable(e))
        }).
        flatMap {
          case 0 => IO.pure(())
          case n =>
            logger.error(s"System command returned with code $n")
            IO.raiseError(ClientError(s"Non-zero exit code: $n", stderr.toSeq: _*))
        }
  }
}
