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

  def linkPrefix: Matcher[Task, String] =
    param[String]("mdLinkPrefix").?.map {
      case Some(p) => p
      case None => ""
    }

  def manual(prefix: Matcher[Task, String], ctx: md.Context): Route[Task] =
    Get >> ifNoneMatch :: prefix :/: restPath :: linkPrefix map {
      case noneMatch :: otherPrefix :: p :: mdPrefix :: HNil =>
        md.toc.find(p) match {
          case Some(mf) =>
            val tag = mf.checksum + mdPrefix
            if (Some(tag) == noneMatch) Stream.emit(emptyResponse(NotModified))
            else Stream.emit(emptyResponse(Ok).
              withHeader(ETag(EntityTag(tag, false))).
              withStreamBody(mf.read(ctx, otherPrefix+"/", mdPrefix))(encoder(mf.mimetype)))

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
