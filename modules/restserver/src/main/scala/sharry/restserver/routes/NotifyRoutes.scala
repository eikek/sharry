package sharry.restserver.routes

import cats.effect.*
import cats.implicits.*

import sharry.backend.BackendApp
import sharry.backend.auth.AuthToken
import sharry.backend.mail.NotifyResult
import sharry.common.*
import sharry.restapi.model.BasicResult
import sharry.restserver.config.Config
import sharry.restserver.http4s.ClientRequestInfo

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder.*
import org.http4s.dsl.Http4sDsl

object NotifyRoutes {

  def apply[F[_]: Async](
      backend: BackendApp[F],
      token: AuthToken,
      cfg: Config
  ): HttpRoutes[F] = {
    val logger = sharry.logging.getLogger[F]
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case req @ POST -> Root / "notify" / Ident(id) =>
      token.account.alias match {
        case Some(alias) =>
          val baseurl = ClientRequestInfo.getBaseUrl(cfg, req) / "app" / "upload"
          for {
            _ <- logger.debug("Notify about alias upload")
            res <- backend.mail.notifyAliasUpload(alias, id, baseurl)
            resp <- Ok(basicResult(res))
          } yield resp

        case None =>
          NotFound()
      }
    }
  }

  private def basicResult(n: List[NotifyResult]): BasicResult =
    n match {
      case Nil =>
        BasicResult(success = false, "There is no email to notify")

      case NotifyResult.InvalidAlias :: Nil =>
        BasicResult(success = false, "Invalid alias")

      case NotifyResult.FeatureDisabled :: Nil =>
        BasicResult(success = false, "Mail feature is disabled.")

      case _ =>
        val success = n.filter(_.isSuccess).size
        val fails = n.filter(_.isError).size
        if (fails > 0 && success == 0)
          BasicResult(success = false, s"Sending failed to all recipients ($fails)")
        else if (fails > 0)
          BasicResult(
            success = true,
            s"Sending succeeded for $success, but failed for $fails recipients"
          )
        else BasicResult(success = true, "Mail sent")
    }

}
