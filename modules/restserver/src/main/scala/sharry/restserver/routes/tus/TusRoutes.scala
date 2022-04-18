package sharry.restserver.routes.tus

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import sharry.backend.BackendApp
import sharry.backend.auth.AuthToken
import sharry.backend.share.{FileInfo, UploadResult}
import sharry.common._
import sharry.restserver.Config

import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers._
import org.typelevel.ci.CIString

object TusRoutes {

  def apply[F[_]: Async](
      shareId: Ident,
      backend: BackendApp[F],
      token: AuthToken,
      cfg: Config,
      rootUrl: LenientUri
  ): HttpRoutes[F] = {
    val logger = sharry.logging.getLogger[F]
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case OPTIONS -> Root =>
        NoContent().map(
          _.putHeaders(TusHeader.resumable, TusHeader.extension, TusHeader.version)
        )

      case req @ POST -> Root =>
        // creation extension
        TusHeader.fileInfo(req) match {
          case Some(info) =>
            backend.share
              .createEmptyFile(shareId, token.account, info)
              .semiflatMap {
                case UploadResult.Success(fid) =>
                  val url = rootUrl / fid.id
                  Created().map(
                    _.putHeaders(
                      TusHeader.resumable,
                      Location(Uri.unsafeFromString(url.asString))
                    )
                  )
                case UploadResult.ValidityExceeded(_) =>
                  BadRequest()
                case UploadResult.SizeExceeded(_) =>
                  PayloadTooLarge("max size exceeded")
                    .map(_.withHeaders(TusMaxSize(cfg.backend.share.maxSize)))
                case UploadResult.PermanentError(msg) =>
                  UnprocessableEntity(msg)
              }
              .getOrElseF(NotFound())

          case None =>
            BadRequest("No length header")
        }

      case req @ (POST | PATCH) -> Root / Ident(fileId) =>
        val offset = UploadOffset.get(req).getOrElse(ByteSize.zero)
        val length = req.headers.get[`Content-Length`].map(_.length).map(ByteSize.apply)
        backend.share
          .addFileData(shareId, fileId, token.account, length, offset, req.body)
          .flatMap {
            case UploadResult.Success(saved) =>
              OptionT.liftF(
                NoContent().map(_.putHeaders(TusHeader.resumable, UploadOffset(saved)))
              )
            case UploadResult.ValidityExceeded(_) =>
              OptionT.liftF(BadRequest("Validity exceeded"))
            case UploadResult.SizeExceeded(_) =>
              OptionT.liftF(PayloadTooLarge("Max size exceeded"))
            case UploadResult.PermanentError(msg) =>
              OptionT.liftF(UnprocessableEntity(msg))
          }
          .getOrElseF(NotFound())

      case HEAD -> Root / Ident(fileId) =>
        (for {
          _ <- OptionT.liftF(logger.debug(s"Return info for file ${fileId.id}"))
          data <- backend.share.getFileData(fileId, token.account)
          resp <- OptionT.liftF(
            Ok().map(
              _.putHeaders(
                TusHeader.resumable,
                UploadOffset(data.saved),
                TusHeader.cacheControl,
                TusMaxSize(cfg.backend.share.maxSize),
                UploadLength(data.length)
              )
            )
          )
        } yield resp).getOrElseF(NotFound())

    }
  }

  object TusHeader {
    private val octetStream = "application/octet-stream"

    def fileInfo[F[_]](req: Request[F]): Option[FileInfo] = {
      val name = SharryFileName(req)
      val len = SharryFileLength(req)
      val mime = SharryFileType(req).getOrElse(octetStream)

      len.map(l => FileInfo(l, name, mime))
    }

    def resumable =
      Header.Raw(CIString("Tus-Resumable"), "1.0.0")
    def extension: Header.Raw =
      Header.Raw(CIString("Tus-Extension"), "creation")
    def version: Header.Raw =
      Header.Raw(CIString("Tus-Version"), "1.0.0")

    def cacheControl =
      `Cache-Control`(CacheDirective.`no-store`)
  }

}
