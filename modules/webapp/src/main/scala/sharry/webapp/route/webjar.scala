package sharry.webapp.route

import java.time.{Instant, ZoneId}
import io.circe.generic.auto._, io.circe.parser._, io.circe.syntax._
import fs2.{text, pipe, Stream, Task}
import shapeless.{HNil, ::}
import scodec.bits.BitVector
import spinoco.fs2.http.routing._
import spinoco.fs2.http.HttpResponse
import spinoco.protocol.mime._
import spinoco.protocol.http.{HttpResponseHeader, HttpStatusCode}
import spinoco.protocol.http.header._
import spinoco.protocol.http.header.value._
import yamusca.implicits._
import yamusca.imports._

import sharry.common.data._

object webjar {
  val webjarToc: Webjars.Toc = readWebjarToc.unsafeRun

  private def readWebjarToc: Task[Webjars.Toc] = {
    def parseToc(json: String): Webjars.Toc =
    decode[Webjars.Toc](json) match {
      case Right(toc) => toc
      case Left(ex) => throw ex
    }

    val tocUrl = Url(getClass.getResource("toc.json"))
    tocUrl.readAll(32 * 1024).
      through(text.utf8Decode).
      fold1(_ + _).
      map(parseToc).
      runLast.
      map(_.get)
  }

  def endpoint(config: RemoteConfig): Route[Task] =
    choice(resourceGet, index(config))


  def ifModifiedSince: Matcher[Task, Option[Instant]] =
    header[`If-Modified-Since`].? map { _.map {
      v => v.value.atZone(ZoneId.of("UTC")).toInstant
    }}

  def ifNoneMatch: Matcher[Task, Option[String]] =
    header[`If-None-Match`].? map {
      case Some(`If-None-Match`(EntityTagRange.Range(List(EntityTag(tag, false))))) => Some(tag)
      case _ => None
    }

  def restPath: Matcher[Task, Seq[String]] =
    path.map(p => p.segments)


  def resourceGet: Route[Task] =
    Get >> ifModifiedSince :: ifNoneMatch :: "static" / as[String] :/: restPath map {
      case modSince :: noneMatch :: name :: rest :: HNil =>
        Stream.emit {
          resource.lookup(name, rest, modSince, noneMatch) match {
            case res @ Find.Found((_, url)) =>
              makeResponse(res, rest).copy(body = url.readAll(8192))
            case res =>
              makeResponse(res, rest)
          }
        }
    }


  def index(config: RemoteConfig): Route[Task] = {
    val indexHtml = html.render(config).runLog.unsafeRun
    Get >> choice(empty, "index.html") >> ifModifiedSince :: ifNoneMatch map {
      case modSince :: noneMatch :: HNil =>
        val index = Seq("index.html")
        Stream.emit {
          resource.lookup("sharry-webapp", index, modSince, noneMatch) match {
            case res @ Find.Found((wj, _)) =>
              makeResponse(res, index, Some(indexHtml.size.toLong)).copy(body = Stream.emits(indexHtml))

            case res =>
              makeResponse(res, index, Some(indexHtml.size.toLong))
          }
        }
    }
  }

  private def makeResponse(find: Find[(Webjars.ModuleId, Url)], path: Seq[String], len: Option[Long] = None): HttpResponse[Task] = {
    def parseContentType(s: String): ContentType =
      ContentType.codec.decodeValue(BitVector.view(s.getBytes("UTF-8"))).require

    def make(wj: Webjars.ModuleId, status: HttpStatusCode): HttpResponse[Task] = {
      val p = path.mkString("/")
      HttpResponse(
        HttpResponseHeader(
          status = status,
          reason = "",
          headers = List(
            Some(ETag(EntityTag(wj.hash, false))),
            Some(`Last-Modified`(Webjars.lastModified.atZone(ZoneId.of("UTC")).toLocalDateTime)),
            webjarToc.get(wj.hash).flatMap(_.get(p)).map(fi => `Content-Type`(parseContentType(fi.contentType))),
            len.orElse(webjarToc.get(wj.hash).flatMap(_.get(p)).map(_.length)).map(`Content-Length`.apply)
          ).collect({case Some(v) => v })),
        Stream.empty
      )
    }
    find match {
      case Find.Found((wj, _)) =>
        make(wj, HttpStatusCode.Ok)
      case Find.NotModified((wj, _)) =>
        make(wj, HttpStatusCode.NotModified)
      case Find.NotFound =>
        HttpResponse(HttpResponseHeader(HttpStatusCode.NotFound, ""), Stream.empty)
    }
  }

  sealed trait Find[+A] {
    def map[B](f: A => B): Find[B]
    def getOrElse[B >: A](a: => B): B
  }
  object Find {
    case class Found[+A](value: A) extends Find[A] {
      def map[B](f: A => B) = Found(f(value))
      def getOrElse[B>:A](a: => B): B = value
    }
    case class NotModified[+A](value: A) extends Find[A] {
      def map[B](f: A => B) = NotModified(f(value))
      def getOrElse[B>:A](a: => B): B = value
    }
    case object NotFound extends Find[Nothing] {
      def map[B](f: Nothing => B) = this
      def getOrElse[B>:Nothing](a: => B): B = a
    }
  }

  object resource {

    def lookup(name: String, path: Seq[String], modSince: Option[Instant] = None, noneMatch: Option[String] = None): Find[(Webjars.ModuleId, Url)] =
      find(name, path) match {
        case Some((wj, url)) if isMatch(wj, noneMatch) || isUnmodified(modSince) =>
          Find.NotModified((wj, url))
        case Some((wj, url)) =>
          Find.Found((wj, url))
        case None =>
          Find.NotFound
      }


    private def find(name: String, path: Seq[String]): Option[(Webjars.ModuleId, Url)] =
      for {
        wj <- Webjars.modules.find(_.artifactId equalsIgnoreCase name)
        url <- wj.localUrl(path.mkString("/"))
      } yield (wj, url)

    def isMatch(wj: Webjars.ModuleId, noneMatch: Option[String]): Boolean =
      Some(wj.hash) == noneMatch

    def isUnmodified(modSince: Option[Instant]): Boolean =
      modSince match {
        case Some(since) => Webjars.lastModified.isBefore(since)
        case _ => false
      }

    private implicit class WebjarOps(wj: Webjars.ModuleId) {

      def localUrl(path: String): Option[Url] = {
        val resource = s"${wj.resourcePrefix}/$path"
        Option(getClass.getResource(resource)).map(Url.apply)
      }

      def cdnUrl(path: String, protocol: String = "http"): Url = {
        val base = s"$protocol://cdn.jsdelivr.net/webjars/org.webjars/${wj.artifactId}/${wj.version}/$path"
        Url(base)
      }
    }
  }

  object html {

    case class Data(config: String, highlightjsTheme: String)
    object Data {
      implicit val dataConverter: ValueConverter[Data] =
        ValueConverter.deriveConverter[Data]
    }

    def render(config: RemoteConfig): Stream[Task, Byte] = {
      resource.lookup("sharry-webapp", Seq("index.html")) match {
        case Find.Found((wj, url)) =>
          val data = Data(config.asJson.spaces4, config.highlightjsTheme)
          url.readAll(8192).
            through(text.utf8Decode).
            fold1(_ + _).
            map(mustache.parse).
            map(_.left.map(err => new Exception(s"${err._2} at ${err._1.pos}"))).
            through(pipe.rethrow).
            map(data.render).
            through(text.utf8Encode)

        case _ => sys.error("index.html not found")
      }
    }
  }
}
