package sharry.restserver.routes

import cats.data.OptionT
import cats.effect.*
import cats.syntax.all.*

import sharry.backend.BackendApp
import sharry.backend.share.*
import sharry.common.*
import sharry.restapi.model.{ShareDetail as ShareDetailDto, *}
import sharry.restserver.config.Config
import sharry.restserver.http4s.ClientRequestInfo
import sharry.restserver.routes.headers.SharryPassword

import org.http4s.*
import org.http4s.circe.CirceEntityEncoder.*
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.*

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

    // Store the verified password in a cookie scoped to this share, so the
    // download links (which can't set the header) still pass the check.
    def withPasswordCookie(resp: Response[F]): Response[F] =
      (shareId, pass) match {
        case (ShareId.PublicId(pid), Some(pw)) =>
          val baseUrl = getBaseUrl(cfg, req)
          val path = baseUrl.path / "api" / "v2" / "open" / "share" / pid.id
          resp.addCookie(
            ResponseCookie(
              SharryPassword.name,
              SharryPassword.encodeCookieValue(pw.pass),
              domain = None,
              path = Some(path.asString),
              httpOnly = true,
              secure = baseUrl.scheme.exists(_.endsWith("s")),
              sameSite = Some(SameSite.Strict)
            )
          )
        case _ => resp
      }

    (for {
      now <- OptionT.liftF(Timestamp.current[F])
      detail <- backend.share.shareDetails(shareId, pass)
      resp <- OptionT.liftF(
        detail.fold(
          d => Ok(shareDetail(now, baseUri)(d)).map(withPasswordCookie),
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
        f.saved,
        f.created
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
