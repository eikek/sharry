package sharry.webapp.route

import java.net.URL
import java.nio.file.{Path, Paths}
import cats.syntax.either._
import fs2.{io, Stream, Task}

case class Url(jurl: URL) {
  require(jurl != null, "url argument must not be null")

  val asString = jurl.toString

  def host = jurl.getHost
  def protocol = jurl.getProtocol
  def path: Option[Path] = Option(jurl.getPath).filter(_.nonEmpty).map(p => Paths.get(p))

  def fileName: Option[String] =
    path.map(_.getFileName.toString)

  def readAll(chunkSize: Int): Stream[Task, Byte] =
    io.readInputStream(Task.delay(jurl.openStream), chunkSize)

  def toJava = jurl
}

object Url {
  def apply(url: String): Url =
    try {
      Url(new URL(url))
    } catch {
      case e: java.net.MalformedURLException =>
        val e2 = new java.net.MalformedURLException(e.getMessage +" ("+ url +")")
        e2.setStackTrace(e.getStackTrace)
        throw e2
    }

  def tryApply(url: String): Either[Throwable, Url] =
    Either.catchNonFatal(apply(url))

  def file(p: Path): Url = Url(s"file://${p.normalize.toAbsolutePath}")

  def resource(name: String): Option[Url] =
    Option(getClass.getClassLoader.getResource(name)).map(Url(_))

  object Parts {
    def unapply(url: Url): Option[(String, String, Option[Path])] =
      Some((url.protocol, url.host, url.path))
  }

  object Protocol {
    def unapply(url: Url): Option[String] =
      Some(url.protocol)
  }

}
