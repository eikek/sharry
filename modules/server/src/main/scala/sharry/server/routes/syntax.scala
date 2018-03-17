package sharry.server.routes

import java.time.{Instant, ZoneId}
import cats.data.Ior
import fs2.{Pipe, Stream}
import cats.effect.IO
import spinoco.fs2.http._
import spinoco.fs2.http.body.{BodyEncoder,StreamBodyEncoder}
import spinoco.fs2.http.routing._
import spinoco.protocol.mime.ContentDisposition
import spinoco.protocol.http.header.value._
import spinoco.protocol.http.header._
import spinoco.protocol.http.{header =>_, _}

import sharry.common.sizes._
import sharry.common.streams

object syntax {

  type Message = Map[String, String]
  object Message {
    def apply(msg: String): Message = Map("message" -> msg)
    def apply(ex: Throwable): Message = apply(ex.getMessage)
  }

  def emptyResponse[F[_]](status: HttpStatusCode): HttpResponse[F] =
    HttpResponse(
      HttpResponseHeader(
        status = status,
        reason = status.label,
        headers = Nil),
      Stream.empty
    )

  val Ok = HttpStatusCode.Ok
  val PartialContent = HttpStatusCode.PartialContent
  val NotFound = HttpStatusCode.NotFound
  val Unauthorized = HttpStatusCode.Unauthorized
  val Forbidden = HttpStatusCode.Forbidden
  val BadRequest = HttpStatusCode.BadRequest
  val Created = HttpStatusCode.Created
  val NoContent = HttpStatusCode.NoContent
  val NotModified = HttpStatusCode.NotModified

  /** Matches any supplied matcher or fails on first with status in `stop`.
    * This is a slightly modified version of original `choice`.
    */
  def choiceUntil[F[_],A](stop: Set[HttpStatusCode])(matcher: Matcher[F, A], matchers: Matcher[F, A]*): Matcher[F, A] = {
    def go(m: Matcher[F,A], next: Seq[Matcher[F, A]]): Matcher[F, A] = {
      next.headOption match {
        case None => m
        case Some(nm) => m.flatMapR {
          case MatchResult.Success(a) => Matcher.success(a)
          case f: MatchResult.Failed[F] if stop contains f.response.header.status => Matcher.respond(f.response)
          case f: MatchResult.Failed[F] => go(nm, next.tail)
        }
      }
    }
    go(matcher, matchers)
  }

  def choice2[F[_],A](matcher: Matcher[F, A], matchers: Matcher[F, A]*): Matcher[F, A] =
    choiceUntil[F,A](Set(Unauthorized, Forbidden))(matcher, matchers: _*)

  implicit final class ResponseBuilder(val status: HttpStatusCode) extends AnyVal {
    def noBody: HttpResponse[IO] = emptyResponse[IO](status)

    def body[A](body: A)(implicit enc: BodyEncoder[A]): HttpResponse[IO] =
      emptyResponse[IO](status).withBody(body)

    def streamBody[A](body: Stream[IO,A])(implicit enc: StreamBodyEncoder[IO,A]): HttpResponse[IO] =
      noBody.withStreamBody(body)(enc)

    def message(msg: String) = body(Message(msg))
    def message(err: Throwable) = body(Message(err))

    def whenEmpty:Pipe[IO,HttpResponse[IO],HttpResponse[IO]] =
      _.through(streams.ifEmpty(Stream.emit(emptyResponse[IO](status)).covary[IO]))
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

  def withDisposition[F[_]](value: String, filename: String): ResponseUpdate[F] =
    _.withHeader(`Content-Disposition`(ContentDisposition(value, Map("filename" -> filename))))


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
        case _ => MatchResult.reply(HttpStatusCode.Unauthorized)
      }
    }

}
