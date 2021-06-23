package sharry.restserver.routes

import cats.effect._
import cats.implicits._

import sharry.backend.BackendApp
import sharry.backend.signup.OSignup.RegisterData
import sharry.backend.signup.{NewInviteResult, SignupResult}
import sharry.restapi.model._
import sharry.restserver.Config

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.log4s._

object RegisterRoutes {
  private[this] val logger = getLogger

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
            res  <- backend.signup.register(cfg.backend.signup)(convert(data))
            resp <- Ok(convert(res))
          } yield resp
        }
      def genInvite =
        HttpRoutes.of { case req @ POST -> Root / "newinvite" =>
          for {
            data <- req.as[GenInvite]
            res  <- backend.signup.newInvite(cfg.backend.signup)(data.password)
            resp <- Ok(convert(res))
          } yield resp
        }
    }
  }

  def convert(r: NewInviteResult): InviteResult =
    r match {
      case NewInviteResult.Success(id) =>
        InviteResult(true, "New invitation created.", Some(id))
      case NewInviteResult.InvitationDisabled =>
        InviteResult(false, "Signing up is not enabled for invitations.", None)
      case NewInviteResult.PasswordMismatch =>
        InviteResult(false, "Password is invalid.", None)
    }

  def convert(r: SignupResult): BasicResult =
    r match {
      case SignupResult.AccountExists =>
        BasicResult(false, "An account with this name already exists.")
      case SignupResult.InvalidInvitationKey =>
        BasicResult(false, "Invalid invitation key.")
      case SignupResult.SignupClosed =>
        BasicResult(false, "Sorry, registration is closed.")
      case SignupResult.Failure(ex) =>
        logger.error(ex)("Error signing up")
        BasicResult(false, s"Internal error: ${ex.getMessage}")
      case SignupResult.Success =>
        BasicResult(true, "Signup successful")
    }

  def convert(r: Registration): RegisterData =
    RegisterData(r.login, r.password, r.invite)
}
