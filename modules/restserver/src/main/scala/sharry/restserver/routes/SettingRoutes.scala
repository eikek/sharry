package sharry.restserver.routes

import cats.effect._
import cats.implicits._

import sharry.backend.BackendApp
import sharry.backend.auth.AuthToken
import sharry.common.AccountSource
import sharry.common.syntax.all._
import sharry.restapi.model._

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.log4s.getLogger

object SettingRoutes {
  private[this] val logger = getLogger

  def apply[F[_]: Effect](
      backend: BackendApp[F],
      token: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "email" =>
        for {
          in   <- req.as[EmailChange]
          _    <- logger.fdebug(s"Changing email for ${token.account} to $in")
          res  <- backend.account.setEmail(token.account.id, in.email.some)
          resp <- Ok(Conv.basicResult(res, "E-Mail successfully changed."))
        } yield resp

      case DELETE -> Root / "email" =>
        for {
          _    <- logger.fdebug(s"Delete email for ${token.account}")
          res  <- backend.account.setEmail(token.account.id, None)
          resp <- Ok(Conv.basicResult(res, "E-Mail successfully deleted."))
        } yield resp

      case GET -> Root / "email" =>
        for {
          acc <- backend.account.findById(token.account.id)
          email = acc.flatMap(_.email)
          resp <- Ok(EmailInfo(email))
        } yield resp

      case req @ POST -> Root / "password" =>
        for {
          in <- req.as[PasswordChange]
          _  <- logger.fdebug(s"Changing password for ${token.account}")
          res <- backend.account.changePassword(
            token.account.id,
            in.oldPassword,
            in.newPassword
          )
          resp <- Ok(Conv.basicResult(res, "Password successfully changed."))
        } yield resp

      case GET -> Root / "password" =>
        for {
          a <- backend.account.findById(token.account.id)
          res = a.exists(_.source == AccountSource.Intern)
          resp <- Ok(
            BasicResult(res, if (res) "Account available" else "Account not available")
          )
        } yield resp
    }
  }
}
