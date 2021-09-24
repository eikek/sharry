package sharry.restserver.routes

import cats.effect._
import cats.implicits._

import sharry.backend.BackendApp
import sharry.backend.auth.AuthToken
import sharry.backend.mail.NotifyResult
import sharry.common._
import sharry.common.syntax.all._
import sharry.restapi.model.BasicResult
import sharry.restserver.Config
import sharry.restserver.http4s.ClientRequestInfo

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.log4s.getLogger

object NotifyRoutes {

  private[this] val logger = getLogger

  def apply[F[_]: Async](
      backend: BackendApp[F],
      token: AuthToken,
      cfg: Config
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case req @ POST -> Root / "notify" / Ident(id) =>
      token.account.alias match {
        case Some(alias) =>
          val baseurl = ClientRequestInfo.getBaseUrl(cfg, req) / "app" / "upload"
          for {
            _ <- logger.fdebug("Notify about alias upload")
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
        BasicResult(false, "There is no email to notify")

      case NotifyResult.InvalidAlias :: Nil =>
        BasicResult(false, "Invalid alias")

      case NotifyResult.FeatureDisabled :: Nil =>
        BasicResult(false, "Mail feature is disabled.")

      case _ =>
        val success = n.filter(_.isSuccess).size
        val fails = n.filter(_.isError).size
        if (fails > 0 && success == 0)
          BasicResult(false, s"Sending failed to all recipients ($fails)")
        else if (fails > 0)
          BasicResult(
            true,
            s"Sending succeeded for $success, but failed for $fails recipients"
          )
        else BasicResult(true, "Mail sent")
    }

}
