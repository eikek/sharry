package sharry.restserver.routes

import cats.effect.*
import cats.implicits.*

import sharry.backend.BackendApp
import sharry.backend.auth.AuthToken
import sharry.common.AccountSource
import sharry.restapi.model.*

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder.*
import org.http4s.circe.CirceEntityEncoder.*
import org.http4s.dsl.Http4sDsl

object SettingRoutes {
  def apply[F[_]: Async](
      backend: BackendApp[F],
      token: AuthToken
  ): HttpRoutes[F] = {
    val logger = sharry.logging.getLogger[F]
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "email" =>
        for {
          in <- req.as[EmailChange]
          _ <- logger.debug(s"Changing email for ${token.account} to $in")
          res <- backend.account.setEmail(token.account.id, in.email.some)
          resp <- Ok(Conv.basicResult(res, "E-Mail successfully changed."))
        } yield resp

      case DELETE -> Root / "email" =>
        for {
          _ <- logger.debug(s"Delete email for ${token.account}")
          res <- backend.account.setEmail(token.account.id, None)
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
          _ <- logger.debug(s"Changing password for ${token.account}")
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
