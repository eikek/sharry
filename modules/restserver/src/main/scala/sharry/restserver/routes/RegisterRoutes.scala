package sharry.restserver.routes

import cats.effect.*
import cats.implicits.*

import sharry.backend.BackendApp
import sharry.backend.signup.OSignup.RegisterData
import sharry.backend.signup.{NewInviteResult, SignupResult}
import sharry.restapi.model.*
import sharry.restserver.config.Config

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder.*
import org.http4s.circe.CirceEntityEncoder.*
import org.http4s.dsl.Http4sDsl

object RegisterRoutes {

  trait InternRoutes[F[_]] {
    def signup: HttpRoutes[F]
    def genInvite: HttpRoutes[F]
  }

  def apply[F[_]: Async](backend: BackendApp[F], cfg: Config): InternRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    new InternRoutes[F] {
      def signup =
        HttpRoutes.of { case req @ POST -> Root / "register" =>
          for {
            data <- req.as[Registration]
            res <- backend.signup.register(cfg.backend.signup)(convert(data))
            resp <- Ok(convert(res))
          } yield resp
        }
      def genInvite =
        HttpRoutes.of { case req @ POST -> Root / "newinvite" =>
          for {
            data <- req.as[GenInvite]
            res <- backend.signup.newInvite(cfg.backend.signup)(data.password)
            resp <- Ok(convert(res))
          } yield resp
        }
    }
  }

  def convert(r: NewInviteResult): InviteResult =
    r match {
      case NewInviteResult.Success(id) =>
        InviteResult(success = true, "New invitation created.", Some(id))
      case NewInviteResult.InvitationDisabled =>
        InviteResult(success = false, "Signing up is not enabled for invitations.", None)
      case NewInviteResult.PasswordMismatch =>
        InviteResult(success = false, "Password is invalid.", None)
    }

  def convert(r: SignupResult): BasicResult =
    r match {
      case SignupResult.AccountExists =>
        BasicResult(success = false, "An account with this name already exists.")
      case SignupResult.InvalidInvitationKey =>
        BasicResult(success = false, "Invalid invitation key.")
      case SignupResult.SignupClosed =>
        BasicResult(success = false, "Sorry, registration is closed.")
      case SignupResult.Failure(ex) =>
        BasicResult(success = false, s"Internal error: ${ex.getMessage}")
      case SignupResult.Success =>
        BasicResult(success = true, "Signup successful")
    }

  def convert(r: Registration): RegisterData =
    RegisterData(r.login, r.password, r.invite)
}
