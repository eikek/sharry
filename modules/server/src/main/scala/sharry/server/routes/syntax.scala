package sharry.server.routes

import java.time.{Instant, ZoneId}
import cats.data.Ior
import fs2.{Pipe, Stream}
import spinoco.fs2.http._
import spinoco.fs2.http.body.{BodyEncoder, StreamBodyEncoder}
import spinoco.fs2.http.routing._
import spinoco.protocol.http.header.value._
import spinoco.protocol.http.header._
import spinoco.protocol.http.{header =>_, _}

import sharry.store.data.sizes._
import sharry.store.data.streams

object syntax {
  def emptyResponse[F[_]](status: HttpStatusCode): HttpResponse[F] =
    HttpResponse(
      HttpResponseHeader(
        status = status,
        reason = "",
        headers = Nil),
      Stream.empty
    )

  object Ok {
    def apply[F[_]](): HttpResponse[F] = emptyResponse(HttpStatusCode.Ok)
    def apply[F[_], A](body: A)(implicit enc: BodyEncoder[A]): HttpResponse[F] = apply().withBody(body)
    def apply[F[_], A](body: Stream[F, A])(implicit enc: BodyEncoder[A]): HttpResponse[F] =
      apply().withStreamBody(body)(StreamBodyEncoder.fromBodyEncoder[F,A])
  }

  object PartialContent {
      def apply[F[_]](): HttpResponse[F] = emptyResponse(HttpStatusCode.PartialContent)
  }

  object NotFound {
    def apply[F[_]](): HttpResponse[F] = emptyResponse(HttpStatusCode.NotFound)
    def apply[F[_], A](body: A)(implicit enc: BodyEncoder[A]): HttpResponse[F] = apply().withBody(body)
    def whenEmpty[F[_]]: Pipe[F, HttpResponse[F], HttpResponse[F]] =
      _.through(streams.ifEmpty(Stream.emit(apply())))
  }

  object NotModified {
    def apply[F[_]](): HttpResponse[F] = emptyResponse(HttpStatusCode.NotModified)
  }

  object Unauthorized {
    def apply[F[_]](): HttpResponse[F] = emptyResponse(HttpStatusCode.Unauthorized)
    def apply[F[_], A](body: A)(implicit enc: BodyEncoder[A]): HttpResponse[F] = apply().withBody(body)
  }

  object BadRequest {
    def apply[F[_]](): HttpResponse[F] = emptyResponse(HttpStatusCode.BadRequest)
    def apply[F[_], A](body: A)(implicit enc: BodyEncoder[A]): HttpResponse[F] = apply().withBody(body)
  }

  object Created {
    def apply[F[_]](): HttpResponse[F] = emptyResponse(HttpStatusCode.Created)
    def apply[F[_], A](body: A)(implicit enc: BodyEncoder[A]): HttpResponse[F] = apply().withBody(body)
  }

  type ResponseUpdate[F[_]] = HttpResponse[F] => HttpResponse[F]
  object ResponseUpdate {
    def identity[F[_]]: ResponseUpdate[F] = identity
  }

  implicit final class ResponseOps[F[_]](val r: HttpResponse[F]) extends AnyVal {
    def ++(f: ResponseUpdate[F]): HttpResponse[F] = f(r)
  }

  def withContentLength[F[_]](len: Long): ResponseUpdate[F] =
    _.withHeader(`Content-Length`(len))

  def withContentLength[F[_]](value: Ior[Int, Int], length: Size): ResponseUpdate[F] =
    _.withHeader {
      value match {
        case Ior.Left(n) => `Content-Length`(length.toBytes - n)
        case Ior.Right(n) => `Content-Length`(n.toLong)
        case Ior.Both(a, b) => `Content-Length`((b - a).toLong + 1)
      }
    }

  def withAcceptRanges[F[_]]: ResponseUpdate[F] =
    _.withHeader(`Accept-Ranges`(Some(RangeUnit.Bytes)))

  def withETag[F[_]](id: String): ResponseUpdate[F] =
    _.withHeader(ETag(EntityTag(id, false)))

  def withLastModified[F[_]](time: Instant): ResponseUpdate[F] =
    _.withHeader(`Last-Modified`(time.atZone(ZoneId.of("UTC")).toLocalDateTime))

  private val goodChars: Set[Byte] = (('a' to 'z') ++ ('A' to 'Z') ++ ('0' to '9') ++ "_-.".toCharArray).map(_.toByte).toSet

  def withDisposition[F[_]](value: String, filename: String): ResponseUpdate[F] = {
    val fname = filename.getBytes("UTF-8").foldLeft("") { (str, b) =>
      val c = if (!goodChars.contains(b)) "%%%X".format(b) else b.toChar.toString
      str + c
    }
    // note: the Map() params are not correctly rendered (values are quoted)
    _.withHeader(`Content-Disposition`(ContentDisposition(s"$value; filename*=UTF-8''$fname", Map())))
  }

  def withContentRange[F[_]](bytes: Ior[Int, Int], length: Size): ResponseUpdate[F] =
    _.withHeader {
      bytes match {
        case Ior.Left(n) => `Content-Range`(n.toLong, length.toBytes -1, Some(length.toBytes))
        case Ior.Right(n) => `Content-Range`(0, n.toLong, Some(length.toBytes))
        case Ior.Both(a, b) => `Content-Range`(a.toLong, b.toLong, Some(length.toBytes))
      }
    }

  def withCookie[F[_]](domain: String, path: String)(name: String, value: String): ResponseUpdate[F] = {
    val cookie = HttpCookie(name = name
      , content =  value
      , httpOnly = true
      , maxAge = None
      , path = Some(path)
      , domain = Some(domain)
      , params = Map.empty
      , expires = None
      , secure = false
    )
    _.withHeader(`Set-Cookie`(cookie))
  }




  def cookie[F[_]](name: String): Matcher[F, HttpCookie] =
    Matcher.Match[Nothing, HttpCookie] { (request, _) =>
      request.headers.collectFirst({ case Cookie(hc) if hc.name == name => hc}) match {
        case None => MatchResult.BadRequest
        case Some(h) => MatchResult.Success(h)
      }
    }

  def Head = method(HttpMethod.HEAD)

  def ifNoneMatch[F[_]]: Matcher[F, Option[String]] =
    header[`If-None-Match`].? map {
      case Some(`If-None-Match`(EntityTagRange.Range(List(EntityTag(tag, false))))) => Some(tag)
      case _ => None
    }

  def range: Matcher[Nothing, Option[Ior[Int, Int]]] =
    header[Range].?.map(_.map {
      case Range(ByteRange.Slice(first, last)) =>
        Ior.both(first.toInt, last.toInt)
      case Range(ByteRange.FromOffset(offset)) =>
        Ior.left(offset.toInt)
      case Range(ByteRange.Suffix(suffix)) =>
        Ior.right(suffix.toInt)
    })


  def aliasId: Matcher[Nothing, String] =
    Matcher.Match[Nothing, String] { (header, _) =>
      val h = header.headers.find { h =>
        h.name.toLowerCase == authz.aliasHeaderName.toLowerCase
      }
      h match {
        case Some(GenericHeader(_, value)) => MatchResult.success(value.trim)
        case _ => MatchResult.reply(HttpStatusCode.Forbidden)
      }
    }

}
