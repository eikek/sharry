package sharry.restserver.routes

import cats.data.OptionT
import cats.effect.Sync
import cats.implicits._
import fs2.Stream

import sharry.backend.BackendApp
import sharry.backend.share._
import sharry.common._
import sharry.store.records.RFileMeta

import binny.ByteRange
import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers._
import org.typelevel.ci.CIString

object ByteResponse {

  def apply[F[_]: Sync](
      dsl: Http4sDsl[F],
      req: Request[F],
      backend: BackendApp[F],
      shareId: ShareId,
      pass: Option[Password],
      chunkSize: ByteSize,
      fid: Ident
  ): F[Response[F]] =
    req.headers
      .get[Range]
      .map(_.ranges.head)
      .map(sr => range(dsl, req, sr, backend, shareId, pass, chunkSize, fid))
      .getOrElse(all(dsl, req, backend, shareId, pass, fid))

  def range[F[_]: Sync](
      dsl: Http4sDsl[F],
      req: Request[F],
      sr: Range.SubRange,
      backend: BackendApp[F],
      shareId: ShareId,
      pass: Option[Password],
      chunkSize: ByteSize,
      fid: Ident
  ): F[Response[F]] = {
    import dsl._

    val rangeDef = makeBinnyByteRange(sr, chunkSize)
    (for {
      file <- backend.share.loadFile(shareId, fid, pass, rangeDef)
      resp <- OptionT.liftF {
        if (rangeInvalid(file.fileMeta, sr)) RangeNotSatisfiable()
        else if (file.fileMeta.length <= chunkSize) allBytes(dsl, req, file)
        else partialResponse(dsl, req, file, chunkSize, sr)
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
      file <- backend.share.loadFile(shareId, fid, pass, ByteRange.All)
      resp <- OptionT.liftF(allBytes(dsl, req, file))
    } yield resp).getOrElseF(NotFound())
  }

  def allBytes[F[_]: Sync](
      dsl: Http4sDsl[F],
      req: Request[F],
      file: FileRange[F]
  ): F[Response[F]] = {
    import dsl._

    val isHead = req.method == Method.HEAD
    val data = if (!isHead) file.data else Stream.empty
    etagResponse(dsl, req, file).getOrElseF(
      Ok(data)
        .map(setETag(file.fileMeta))
        .map(
          _.putHeaders(
            `Content-Type`(mediaType(file)),
            `Accept-Ranges`.bytes,
            `Last-Modified`(timestamp(file)),
            `Content-Disposition`("inline", fileNameMap(file)),
            `Content-Length`(file.fileMeta.length.bytes),
            fileSizeHeader(file.fileMeta.length)
          )
        )
    )
  }

  private def etagResponse[F[_]: Sync](
      dsl: Http4sDsl[F],
      req: Request[F],
      file: FileRange[F]
  ): OptionT[F, Response[F]] = {
    import dsl._

    val noneMatch = req.headers.get[`If-None-Match`].flatMap(_.tags).map(_.head.tag)

    if (noneMatch.contains(file.fileMeta.checksum.toHex)) OptionT.liftF(NotModified())
    else OptionT.none
  }

  private def partialResponse[F[_]: Sync](
      dsl: Http4sDsl[F],
      req: Request[F],
      file: FileRange[F],
      chunkSize: ByteSize,
      range: Range.SubRange
  ): F[Response[F]] = {
    import dsl._

    val fileLen = file.fileMeta.length
    val respLen =
      range.second.map(until => until - range.first + 1).getOrElse(chunkSize.bytes)
    val respRange =
      Range.SubRange(range.first, range.second.getOrElse(range.first + chunkSize.bytes))

    val isHead = req.method == Method.HEAD
    val data = if (isHead) Stream.empty else file.data.take(respLen.toLong)
    PartialContent(data).map(
      _.withHeaders(
        `Accept-Ranges`.bytes,
        `Content-Type`(mediaType(file)),
        `Last-Modified`(timestamp(file)),
        `Content-Disposition`("inline", fileNameMap(file)),
        fileSizeHeader(file.fileMeta.length),
        `Content-Range`(RangeUnit.Bytes, respRange, Some(fileLen.bytes))
      )
    )
  }

  private def makeBinnyByteRange(sr: Range.SubRange, chunkSize: ByteSize): ByteRange =
    sr.second
      .map(until => ByteRange(sr.first, (until - sr.first + 1).toInt))
      .getOrElse {
        if (sr.first == 0) ByteRange(0, chunkSize.bytes.toInt)
        else ByteRange(sr.first, chunkSize.bytes.toInt)
      }

  private def setETag[F[_]](fm: RFileMeta)(r: Response[F]): Response[F] =
    if (fm.checksum.isEmpty) r
    else r.putHeaders(ETag(fm.checksum.toHex))

  private def rangeInvalid(file: RFileMeta, range: Range.SubRange): Boolean =
    range.first < 0 || range.second.exists(t => t < range.first || t > file.length.bytes)

  private def mediaType[F[_]](file: FileRange[F]) =
    MediaType.unsafeParse(file.fileMeta.mimetype)

  private def timestamp[F[_]](file: FileRange[F]) =
    HttpDate.unsafeFromInstant(file.fileMeta.created.value)

  private def fileNameMap[F[_]](file: FileRange[F]) =
    file.shareFile.filename.map(n => Map(CIString("filename") -> n)).getOrElse(Map.empty)

  private def fileSizeHeader(sz: ByteSize) =
    Header.Raw(CIString("File-Size"), sz.bytes.toString)
}
