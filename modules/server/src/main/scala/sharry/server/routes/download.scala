package sharry.server.routes

import java.time.Instant
import cats.data.Ior
import fs2.{Pipe, Strategy, Stream, Task}
import shapeless.{::,HNil}
import scodec.bits.{BitVector, ByteVector}
import spinoco.protocol.http.header.value.ContentType
import spinoco.fs2.http.body.StreamBodyEncoder
import spinoco.fs2.http.HttpResponse
import spinoco.fs2.http.routing._

import sharry.store.range._
import sharry.common.data._
import sharry.common.mime._
import sharry.common.streams
import sharry.server.paths
import sharry.server.config._
import sharry.store.upload.UploadStore
import sharry.server.routes.syntax._

object download {

  type ResponseOr[A] = Either[HttpResponse[Task], A]
  private implicit val zipPool = Strategy.fromFixedDaemonPool(10, "sharry-zip")

  def endpoint(auth: AuthConfig, webCfg: WebConfig, store: UploadStore) =
    choice2(downloadZip(auth, store)
      , download(auth, store)
      , downloadPublishedZip(store)
      , downloadPublished(webCfg, store)
      , downloadHead(auth, store)
      , downloadPublishedHead(store)
      , checkPassword(webCfg, store))


  def download(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Get >> paths.download.matcher / as[String] :: range :: ifNoneMatch :: authz.user(authCfg) map {
      case id :: bytes :: noneMatch :: user :: HNil =>
        // get file if owned by user
        store.getUploadByFileId(id, user).
          map({ case (_, f) => Right(f) }).
          through(unmodifiedWhen(noneMatch, f => f.meta.id, standardHeaders)).
          through(bytes.map(deliverPartial(store)).getOrElse(deliver(store))).
          through(NotFound.whenEmpty)
    }

  def downloadZip(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Get >> paths.downloadZip.matcher / as[String] :: ifNoneMatch :: authz.user(authCfg) map {
      case id :: noneMatch :: user :: HNil =>
        store.getUpload(id, user).
          map(Right(_)).
          through(unmodifiedWhen(noneMatch, info => info.upload.publishId.getOrElse(""), standardHeaders)).
          through(zipUpload(store, standardHeaders)).
          through(NotFound.whenEmpty)
    }

  def downloadHead(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Head >> paths.download.matcher / as[String] :: authz.user(authCfg) map {
      case id :: user :: HNil =>
        store.getUploadByFileId(id, user).
          map(_._2).
          map(standardHeaders).
          map(Ok.noBody ++ _).
          through(NotFound.whenEmpty)
    }

  def downloadPublished(webCfg: WebConfig, store: UploadStore): Route[Task] =
    Get >> paths.downloadPublished.matcher / as[String] :: range ::  ifNoneMatch :: sharryPass map {
      case id :: bytes :: noneMatch :: pass :: HNil =>
        store.getPublishedUploadByFileId(id).
          through(checkDownloadFile(pass)).
          through(unmodifiedWhen(noneMatch, f => f.meta.id, standardHeaders)).
          through(bytes.map(deliverPartial(store)).getOrElse(deliver(store))).
          through(NotFound.whenEmpty)
    }

  def downloadPublishedZip(store: UploadStore): Route[Task] =
    Get >> paths.downloadPublishedZip.matcher / as[String] :: ifNoneMatch :: sharryPass map {
      case id :: noneMatch :: pass :: HNil =>
        store.getPublishedUpload(id).
          through(checkDownload(pass)).
          through(unmodifiedWhen(noneMatch, _ => id, standardHeaders)).
          through(zipUpload(store, standardHeaders)).
          through(NotFound.whenEmpty)
    }

  def downloadPublishedHead(store: UploadStore): Route[Task] =
    Head >> paths.downloadPublished.matcher / as[String] :: sharryPass map {
      case id ::  pass :: HNil =>
        store.getPublishedUploadByFileId(id).
          through(checkDownloadFile(pass)).
          map(_.map(Ok.noBody ++ standardHeaders(_))).
          map(_.fold(identity, identity)).
          through(NotFound.whenEmpty)
    }


  def checkPassword(cfg: WebConfig, store: UploadStore): Route[Task] =
    Post >> paths.checkPassword.matcher / as[String] :: jsonBody[Pass].? map {
      case id :: pass :: HNil =>

        val makeCookie = withCookie[Task](cfg.domain, paths.downloadPublished.path)(
          "sharry_dlpassword", pass.map(_.password).getOrElse(""))

        store.getPublishedUpload(id).map({ info =>
          Upload.checkPassword(info.upload, pass.map(_.password)).
            leftMap(err => List(err)).
            map(_ => List[String]()).
            toEither.
            fold(
              l => Ok.body(l),
              l => Ok.body(l) ++ makeCookie,
            )}).
          through(NotFound.whenEmpty)
    }

  private def sharryPass: Matcher[Nothing, Option[String]] =
    cookie("sharry_dlpassword").map(_.content).?


  private def deliverPartial(store: UploadStore)(bytes: Ior[Int, Int]): Pipe[Task, ResponseOr[UploadInfo.File], HttpResponse[Task]] =
    _.map({
      case Right(file) =>
        val data = store.fetchData(RangeSpec.byteRange(bytes))(Stream.emit(file)).
          through(streams.toByteChunks)

        val mt = file.meta.mimetype
        PartialContent.streamBody(data)(encoder(mt)) ++
          withContentLength(bytes, file.meta.length) ++
          withContentRange(bytes, file.meta.length) ++
          withAcceptRanges ++
          withDisposition("inline", file.filename)
      case Left(r) => r
    })

  private def deliver(store: UploadStore): Pipe[Task, ResponseOr[UploadInfo.File], HttpResponse[Task]] =
    _.map({
      case Right(file) =>
        val data = store.fetchData(RangeSpec.all)(Stream.emit(file)).
          through(streams.toByteChunks)

        val mt = file.meta.mimetype
        Ok.streamBody(data)(encoder(mt)) ++ standardHeaders(file)
      case Left(r) => r
    })

  private def zipUpload(store: UploadStore, modify: UploadInfo => ResponseUpdate[Task]): Pipe[Task, ResponseOr[UploadInfo], HttpResponse[Task]] =
    _.map {
      case Right(info) =>
        val data = Stream.emit(info).
          through(store.zipAll(8192 * 2)).
          through(streams.toByteChunks)
        Ok.streamBody(data)(encoder(MimeType.`application/zip`)) ++
          withDisposition("attachment", info.upload.id+".zip") ++
          modify(info)
      case Left(r) =>
        r
    }

  private def unmodifiedWhen[A](tagOpt: Option[String]
    , id: A => String
    , modify: A => ResponseUpdate[Task]): Pipe[Task, ResponseOr[A], ResponseOr[A]] =
    tagOpt match {
      case None => identity
      case Some(tag) =>
        _.map(_.flatMap { a =>
          if (id(a) == tag) Left(NotModified.noBody ++ modify(a))
          else Right(a)
        })
    }

  private def checkDownload1[A](pass: Option[String]): Pipe[Task, (Upload, A), ResponseOr[(Upload, A)]] =
    _.map { case (upload, a) =>
      Upload.checkUpload(upload, Instant.now, upload.downloads, pass).
        leftMap(err => BadRequest.body(err.toList)).
        map(_ => (upload, a)).
        toEither
    }

  private def checkDownloadFile(pass: Option[String]): Pipe[Task, (Upload, UploadInfo.File), ResponseOr[UploadInfo.File]] =
    _.through(checkDownload1(pass)).
      map(_.map(_._2))

  private def checkDownload[A](pass: Option[String]): Pipe[Task, UploadInfo, ResponseOr[UploadInfo]] =
    _.map(u => (u.upload, u)).
      through(checkDownload1(pass)).
      map(_.map(_._2))

  private def encoder(mt: MimeType): StreamBodyEncoder[Task, ByteVector] =
    StreamBodyEncoder.byteVectorEncoder.withContentType(asContentType(mt))

  private def asContentType(mt: MimeType): ContentType =
    // TODO getOrElse octet-stream
    ContentType.codec.decodeValue(BitVector(mt.asString.getBytes)).require

  private def standardHeaders(file: UploadInfo.File): ResponseUpdate[Task] =
    _ ++ withContentLength(file.meta.length.toBytes) ++
      withAcceptRanges ++
      withETag(file.meta.id) ++
      withLastModified(file.meta.timestamp) ++
      withDisposition("inline", file.filename)

  private def standardHeaders(info: UploadInfo): ResponseUpdate[Task] = {
    _ ++ withLastModified(info.upload.created) ++
      info.upload.publishId.map(withETag[Task]).getOrElse(ResponseUpdate.identity[Task])
  }

}
