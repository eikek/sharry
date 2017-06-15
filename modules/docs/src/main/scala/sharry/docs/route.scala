package sharry.docs

import fs2.{Stream, Task}
import shapeless.{::, HNil}
import scodec.bits.{ByteVector, BitVector}
import spinoco.fs2.http.HttpResponse
import spinoco.fs2.http.body._
import spinoco.fs2.http.routing._
import spinoco.protocol.http.{HttpStatusCode, HttpResponseHeader}
import spinoco.protocol.http.header._
import spinoco.protocol.http.header.value._

object route {

  def ifNoneMatch: Matcher[Task, Option[String]] =
    header[`If-None-Match`].? map {
      case Some(`If-None-Match`(EntityTagRange.Range(List(EntityTag(tag, false))))) => Some(tag)
      case _ => None
    }

  def restPath: Matcher[Task, String] =
    path.map(p => p.segments.mkString("/"))

  def manual(prefix: Matcher[Task, String], ctx: md.Context): Route[Task] =
    Get >> ifNoneMatch :: prefix / restPath map {
      case noneMatch :: p :: HNil =>
        md.toc.find(p) match {
          case Some(mf) =>
            if (Some(mf.checksum) == noneMatch) Stream.emit(emptyResponse(NotModified))
            else Stream.emit(emptyResponse(Ok).
              withHeader(ETag(EntityTag(mf.checksum, false)), `Content-Length`(mf.size)).
              withStreamBody(mf.read(ctx))(encoder(mf.mimetype)))

          case None =>
            Stream.emit(emptyResponse(NotFound))
        }
    }


  private val Ok = HttpStatusCode.Ok
  private val NotFound = HttpStatusCode.NotFound
  private val NotModified = HttpStatusCode.NotModified

  private def emptyResponse[F[_]](status: HttpStatusCode): HttpResponse[F] =
    HttpResponse(
      HttpResponseHeader(
        status = status,
        reason = "",
        headers = Nil),
      Stream.empty
    )

  private def encoder(mt: String): StreamBodyEncoder[Task, ByteVector] =
    StreamBodyEncoder.byteVectorEncoder.withContentType(asContentType(mt))

  private def asContentType(mt: String): ContentType = {
    val ct = ContentType.codec.decodeValue(BitVector(mt.getBytes)).require
    if (mt.startsWith("text/")) ct.copy(charset = Some(HttpCharset.`UTF-8`))
    else ct
  }

}
