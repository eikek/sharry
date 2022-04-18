package sharry.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.syntax.all._

import sharry.backend.BackendApp
import sharry.backend.share._
import sharry.common._
import sharry.restapi.model.{ShareDetail => ShareDetailDto, _}
import sharry.restserver.Config
import sharry.restserver.http4s.ClientRequestInfo

import org.http4s._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers._

object ShareDetailResponse {

  private def getBaseUrl[F[_]](cfg: Config, req: Request[F]): LenientUri =
    ClientRequestInfo.getBaseUrl(cfg, req)

  def apply[F[_]: Sync](
      dsl: Http4sDsl[F],
      req: Request[F],
      backend: BackendApp[F],
      cfg: Config,
      shareId: ShareId,
      pass: Option[Password]
  ): F[Response[F]] = {
    import dsl._
    val logger = sharry.logging.getLogger[F]

    val baseUri = shareId.fold(
      pub => getBaseUrl(cfg, req) / "api" / "v2" / "open" / "share" / pub.id.id / "file",
      priv => getBaseUrl(cfg, req) / "api" / "v2" / "sec" / "share" / priv.id.id / "file"
    )

    val authChallenge = `WWW-Authenticate`(Challenge("sharry", "sharry"))

    (for {
      now <- OptionT.liftF(Timestamp.current[F])
      detail <- backend.share.shareDetails(shareId, pass)
      resp <- OptionT.liftF(
        detail.fold(
          d => Ok(shareDetail(now, baseUri)(d)),
          _ =>
            logger
              .info(
                s"Password challenge failure for share id ${shareId
                    .fold(pub => pub.id.id, priv => priv.id.id)} from ip ${req.from.map(_.toUriString).getOrElse("Unknown ip")}"
              ) *> Forbidden(),
          _ => Unauthorized(authChallenge)
        )
      )
    } yield resp).getOrElseF {
      logger
        .info(
          s"No share with id ${shareId
              .fold(pub => pub.id.id, priv => priv.id.id)}. Attempt by ip ${req.from.map(_.toUriString).getOrElse("Unknown ip")}"
        ) *> NotFound()
    }
  }

  def shareDetail(now: Timestamp, baseUri: LenientUri)(
      item: ShareDetail
  ): ShareDetailDto = {
    val files = item.files.map(f =>
      ShareFile(
        f.id,
        f.name.getOrElse(""),
        f.length,
        f.mimetype,
        f.checksum,
        f.saved
      )
    )

    ShareDetailDto(
      item.share.id,
      item.share.name,
      item.share.aliasId,
      item.alias.map(_.name),
      item.share.validity,
      item.share.maxViews,
      item.share.password.nonEmpty,
      item.share.description,
      item.descProcessed(baseUri),
      item.share.created,
      item.published.map(p =>
        SharePublish(
          p.id,
          p.enabled,
          p.views,
          p.publishDate,
          p.publishUntil,
          p.publishUntil.isBefore(now),
          p.lastAccess
        )
      ),
      files.toList
    )
  }
}
