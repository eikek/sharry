package sharry.cli

import java.util.concurrent.atomic.AtomicLong

import cats.data.NonEmptyList
import fs2.{Sink, Stream}
import cats.effect.IO
import Console._
import StdoutSink._

import sharry.common.sizes._
import sharry.common.file._
import sharry.common.data.Upload
import sharry.cli.config._
import sharry.cli.Progress._

final class StdoutSink(cfg: Config, latch: java.util.concurrent.CountDownLatch) extends Sink[IO, Progress] {

  private final val start: AtomicLong = new AtomicLong(0)

  def apply(in: Stream[IO, Progress]): Stream[IO, Unit] = in.map {
    case Init =>

    case Prepare(cfg) =>
      if (cfg.files.nonEmpty) {
        val size = cfg.files.foldLeft(0L)(_ + _.length).bytes
        info(s"Prepare to upload ${cfg.files.size} files (${size.asString}) to ${cfg.endpoint.asString}.")
        Console.flush()
      }

    case ServerWelcome(ctx) =>
      if (ctx.remoteConfig.welcomeMessage.nonEmpty) {
        info(cyan(ctx.remoteConfig.welcomeMessage))
      }

    case Authenticating(host) =>
      info(s"Authenticating at ${host.asString}")
      Console.flush()

    case CreateUpload =>
      info("Creating a new upload.")

    case ProcessingMarkdown =>
      info("Processing markdown file.")
      Console.flush()

    case DeleteUpload =>
      info("Deleting upload.")
      Console.flush()

    case PublishUpload =>
      info("Publishing upload.")
      Console.flush()

    case v@VersionMismatch(server) =>
      warn(s"Warning: the server version ($server) does not match this version (${v.cli}).")
      Console.flush()

    case Uploaded(current, total) =>
      start.compareAndSet(0, System.currentTimeMillis())
      val percent = current.toBytes.toDouble / total.toBytes.toDouble
      val perc = "%6.2f".format(percent * 100)
      val width = 58
      val done = repeat((width * percent).toInt, "=")
      val left = repeat(width - (width * percent).toInt, " ")
      val rate = start.get match {
        case 0 => ""
        case s =>
          val secs = (System.currentTimeMillis() - s) / 1000
          if (secs <= 0) ""
          else (current.toBytes / secs).bytes.asString + "/s"
      }
      out.print(s"$perc |$done$left| ${rate}\r")

      if (current == total) {
        out.println("")
      }
      Console.flush()

    case Error(ex) =>
      formatError(ex)
      Console.flush()

    case Done(ctx) =>
      ctx.config.auth match {
        case AuthMethod.AliasHeader(_) =>
          info("Thanks for uploading.")
        case _ =>
          if (ctx.upload != Upload.empty) {
            val publicUrl = ctx.upload.publishId.
              map(id => ctx.config.endpoint.asString +"#id="+id)
            val privateUrl = ctx.config.endpoint.asString +"#uid="+ctx.upload.id
            info(privateUrl)
            publicUrl.foreach(info)
          }
      }
      latch.countDown()

    case Manual(text, html) =>
      info(text)
  }

  def info(line: String): Unit =
    out.println(line)

  def error(line: String): Unit =
    err.println(red(line))

  def warn(line: String): Unit =
    out.println(yellow(line))
}

object StdoutSink {

  def red(s: String): String = RED + s + RESET
  def white(s: String): String = WHITE + s + RESET
  def cyan(s: String): String = CYAN + s + RESET
  def yellow(s: String): String = YELLOW + s + RESET

  @annotation.tailrec
  def repeat(n: Int, s: String, target: String = ""): String =
    if (n <= 0) target
    else repeat(n -1, s, target + s)

  def formatError(ex: Throwable): String =
    ex match {
      case ClientError(all@NonEmptyList(first, rest)) =>
        if (rest == Nil) red(first)
        else red("The following errors occurred:\n") + all.toList.map(item => red(s"- $item")).mkString("\n")
      case _ =>
        red(ex.getMessage)
    }
}
