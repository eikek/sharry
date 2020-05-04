package sharry.restserver.routes

import cats.data.OptionT
import org.http4s._
import org.http4s.headers._
import org.http4s.dsl.Http4sDsl
import org.http4s.circe.CirceEntityEncoder._

import cats.effect.Sync
import sharry.common._
import sharry.backend.share._
import sharry.backend.BackendApp
import sharry.restapi.model.{ShareDetail => ShareDetailDto, _}
import sharry.restserver.Config

object ShareDetailResponse {

  def apply[F[_]: Sync](
      dsl: Http4sDsl[F],
      backend: BackendApp[F],
      cfg: Config,
      shareId: ShareId,
      pass: Option[Password]
  ): F[Response[F]] = {
    import dsl._

    val baseUri = shareId.fold(
      pub => cfg.baseUrl / "api" / "v2" / "open" / "share" / pub.id.id / "file",
      priv => cfg.baseUrl / "api" / "v2" / "sec" / "share" / priv.id.id / "file"
    )

    val authChallenge = `WWW-Authenticate`(Challenge("sharry", "sharry"))

    (for {
      now    <- OptionT.liftF(Timestamp.current[F])
      detail <- backend.share.shareDetails(shareId, pass)
      resp <- OptionT.liftF(
        detail.fold(
          d => Ok(shareDetail(now, baseUri)(d)),
          _ => Forbidden(),
          _ => Unauthorized(authChallenge)
        )
      )
    } yield resp).getOrElseF(NotFound())
  }

  def shareDetail(now: Timestamp, baseUri: LenientUri)(
      item: ShareDetail
  ): ShareDetailDto = {
    val files = item.files.map(f =>
      ShareFile(
        f.id,
        f.name.getOrElse(""),
        f.length,
        f.mimetype.asString,
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
