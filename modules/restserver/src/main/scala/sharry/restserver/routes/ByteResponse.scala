package sharry.restserver.routes

import cats.data.OptionT
import cats.implicits._
import org.http4s._
import org.http4s.headers._
import org.http4s.dsl.Http4sDsl
import bitpeace.FileMeta
import sharry.common._
import sharry.backend.share._
import sharry.backend.BackendApp
import bitpeace.RangeDef
import cats.data.Ior
import cats.effect.Sync

object ByteResponse {

  def apply[F[_]: Sync](
      dsl: Http4sDsl[F],
      req: Request[F],
      backend: BackendApp[F],
      shareId: ShareId,
      pass: Option[Password],
      fid: Ident
  ) =
    req.headers
      .get(Range)
      .map(_.ranges.head)
      .map(sr => range(dsl, sr, req, backend, shareId, pass, fid))
      .getOrElse(all(dsl, req, backend, shareId, pass, fid))

  def range[F[_]: Sync](
      dsl: Http4sDsl[F],
      sr: Range.SubRange,
      req: Request[F],
      backend: BackendApp[F],
      shareId: ShareId,
      pass: Option[Password],
      fid: Ident
  ): F[Response[F]] = {
    import dsl._

    val rangeDef = sr.second
      .map(until => RangeDef.byteRange(Ior.both(sr.first.toInt, until.toInt)))
      .getOrElse {
        if (sr.first == 0) RangeDef.all
        else RangeDef.byteRange(Ior.left(sr.first.toInt))
      }

    (for {
      file <- backend.share.loadFile(shareId, fid, pass, rangeDef)
      resp <- OptionT.liftF {
        if (rangeInvalid(file.fileMeta, sr)) RangeNotSatisfiable()
        else partialResponse(dsl, file, sr)
      }
    } yield resp).getOrElseF(NotFound())
  }

  def all[F[_]: Sync](
      dsl: Http4sDsl[F],
      req: Request[F],
      backend: BackendApp[F],
      shareId: ShareId,
      pass: Option[Password],
      fid: Ident
  ): F[Response[F]] = {
    import dsl._

    (for {
      file <- backend.share.loadFile(shareId, fid, pass, RangeDef.all)
      resp <- OptionT.liftF(
        etag(dsl, req, file).getOrElseF(
          Ok(file.data).map(
            _.withHeaders(
              `Content-Type`(mediaType(file)),
              `Accept-Ranges`.bytes,
              `Last-Modified`(timestamp(file)),
              `Content-Disposition`("inline", fileNameMap(file)),
              ETag(file.fileMeta.checksum),
              `Content-Length`.unsafeFromLong(file.fileMeta.length)
            )
          )
        )
      )
    } yield resp).getOrElseF(NotFound())
  }

  private def etag[F[_]: Sync](
      dsl: Http4sDsl[F],
      req: Request[F],
      file: FileRange[F]
  ): OptionT[F, Response[F]] = {
    import dsl._

    val noneMatch = req.headers.get(`If-None-Match`).flatMap(_.tags).map(_.head.tag)

    if (Some(file.fileMeta.checksum) == noneMatch) OptionT.liftF(NotModified())
    else OptionT.none
  }

  private def partialResponse[F[_]: Sync](
      dsl: Http4sDsl[F],
      file: FileRange[F],
      range: Range.SubRange
  ): F[Response[F]] = {
    import dsl._
    val len = file.fileMeta.length
    PartialContent(file.data).map(
      _.withHeaders(
        `Accept-Ranges`.bytes,
        `Content-Type`(mediaType(file)),
        `Last-Modified`(timestamp(file)),
        `Content-Disposition`("inline", fileNameMap(file)),
        `Content-Length`
          .unsafeFromLong(range.second.getOrElse(len) - range.first),
        `Content-Range`(RangeUnit.Bytes, subRangeResp(range, len), Some(len))
      )
    )
  }

  private def subRangeResp(in: Range.SubRange, length: Long): Range.SubRange =
    in match {
      case Range.SubRange(n, None) =>
        Range.SubRange(n.toLong, Some(length - 1))
      case Range.SubRange(n, Some(t)) =>
        Range.SubRange(n, Some(t))
    }

  private def rangeInvalid(file: FileMeta, range: Range.SubRange): Boolean =
    range.first < 0 || range.second.exists(t => t < range.first || t > file.length)

  private def mediaType[F[_]](file: FileRange[F]) =
    MediaType.unsafeParse(file.fileMeta.mimetype.asString)

  private def timestamp[F[_]](file: FileRange[F]) =
    HttpDate.unsafeFromInstant(file.fileMeta.timestamp)

  private def fileNameMap[F[_]](file: FileRange[F]) =
    file.shareFile.filename.map(n => Map("filename" -> n)).getOrElse(Map.empty)
}
