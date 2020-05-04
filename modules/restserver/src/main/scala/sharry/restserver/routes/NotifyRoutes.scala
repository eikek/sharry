package sharry.restserver.routes

import cats.effect._
import cats.implicits._
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.log4s.getLogger

import sharry.common._
import sharry.common.syntax.all._
import sharry.backend.auth.AuthToken
import sharry.backend.mail.NotifyResult
import sharry.backend.BackendApp
import sharry.restserver.Config
import sharry.restapi.model.BasicResult

object NotifyRoutes {

  private[this] val logger = getLogger

  def apply[F[_]: Effect](
      backend: BackendApp[F],
      token: AuthToken,
      cfg: Config
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "notify" / Ident(id) =>
        token.account.alias match {
          case Some(alias) =>
            val baseurl = cfg.baseUrl / "app" / "upload"
            for {
              _    <- logger.fdebug("Notify about alias upload")
              res  <- backend.mail.notifyAliasUpload(alias, id, baseurl)
              resp <- Ok(basicResult(res))
            } yield resp

          case None =>
            NotFound()
        }
    }
  }

  private def basicResult(n: NotifyResult): BasicResult =
    n match {
      case NotifyResult.InvalidAlias =>
        BasicResult(false, "Invalid alias")

      case NotifyResult.FeatureDisabled =>
        BasicResult(false, "Mail feature is disabled.")

      case NotifyResult.MissingEmail =>
        BasicResult(false, "There is no e-mail address.")

      case NotifyResult.SendFailed(err) =>
        BasicResult(false, s"Sending failed: $err.")

      case NotifyResult.SendSuccessful =>
        BasicResult(true, s"Mail sent.")
    }

}
