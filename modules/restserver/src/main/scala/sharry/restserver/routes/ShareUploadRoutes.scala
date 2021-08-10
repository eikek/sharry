package sharry.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import sharry.backend.BackendApp
import sharry.backend.auth.AuthToken
import sharry.backend.share.{File, ShareData}
import sharry.common._
import sharry.common.syntax.all._
import sharry.restapi.model._
import sharry.restserver.Config
import sharry.restserver.http4s.ClientRequestInfo
import sharry.restserver.routes.tus.TusRoutes

import bitpeace.Mimetype
import org.http4s.HttpRoutes
import org.http4s.Request
import org.http4s.Uri
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.{`Content-Length`, `Content-Type`}
import org.http4s.multipart.Multipart
import org.log4s.getLogger

object ShareUploadRoutes {
  private[this] val logger = getLogger

  def apply[F[_]: Async](
      backend: BackendApp[F],
      token: AuthToken,
      cfg: Config,
      uploadPathPrefix: LenientUri.Path
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root =>
        for {
          _         <- logger.fdebug("Uploading files to create a new share.")
          multipart <- req.as[Multipart[F]]
          updata    <- readMultipart(multipart)
          upid      <- backend.share.create(updata, token.account)
          res       <- Ok(Conv.uploadResult("Share created.")(upid))
        } yield res

      case req @ POST -> Root / "new" =>
        for {
          _  <- logger.fdebug("Create empty share")
          in <- req.as[ShareProperties]
          updata = ShareData[F](
            in.validity,
            in.maxViews,
            in.description,
            in.password,
            in.name,
            Stream.empty
          )
          upid <- backend.share.create(updata, token.account)
          res  <- Ok(Conv.uploadResult("Share created.")(upid))
        } yield res

      case req @ POST -> Root / Ident(id) / "files" / "add" =>
        (for {
          _         <- OptionT.liftF(logger.fdebug("Uploading a file to an existing share"))
          multipart <- OptionT.liftF(req.as[Multipart[F]])
          updata    <- OptionT.liftF(readMultipart(multipart))
          ur        <- backend.share.addFile(id, token.account, updata.files)
          resp      <- OptionT.liftF(Ok(Conv.uploadBasicResult("File(s) added")(ur)))
        } yield resp).getOrElseF(NotFound())

      case req @ (PATCH | POST | GET | OPTIONS | HEAD) -> Ident(
            id
          ) /: "files" /: "tus" /: _ =>
        val pi      = req.pathInfo.renderString.substring(id.id.length() + 11)
        val rootUri = getBaseUrl(cfg, req) ++ uploadPathPrefix / id.id / "files" / "tus"
        TusRoutes(id, backend, token, cfg, rootUri)
          .run(req.withPathInfo(Uri.Path.unsafeFromString(pi)))
          .getOrElseF(NotFound())
    }
  }

  def readMultipart[F[_]: Async](mp: Multipart[F]): F[ShareData[F]] = {
    def parseMeta(body: Stream[F, Byte]): F[ShareProperties] =
      body
        .through(fs2.text.utf8.decode)
        .parseJsonAs[ShareProperties]
        .map(
          _.fold(
            ex => {
              logger.error(ex)("Reading upload metadata failed.")
              throw ex
            },
            identity
          )
        )

    def fromContentType(header: `Content-Type`): Mimetype =
      Mimetype(header.mediaType.mainType, header.mediaType.subType)

    val meta: F[ShareProperties] = mp.parts
      .find(_.name.exists(_.equalsIgnoreCase("meta")))
      .map(p => parseMeta(p.body))
      .getOrElse(ShareProperties(None, Duration.days(2), None, 30, None).pure[F])

    val files = mp.parts
      .filter(p => p.name.forall(s => !s.equalsIgnoreCase("meta")))
      .map(p =>
        File(
          p.filename,
          p.headers.get[`Content-Type`].map(fromContentType),
          p.headers.get[`Content-Length`].map(_.length),
          p.body
        )
      )

    for {
      metaData <- meta
      _        <- logger.fdebug(s"Parsed upload meta data: $metaData")
      shd = ShareData[F](
        metaData.validity,
        metaData.maxViews,
        metaData.description,
        metaData.password,
        metaData.name,
        Stream.emits(files)
      )
    } yield shd
  }

  private def getBaseUrl[F[_]](cfg: Config, req: Request[F]): LenientUri =
    ClientRequestInfo.getBaseUrl(cfg, req)

}
