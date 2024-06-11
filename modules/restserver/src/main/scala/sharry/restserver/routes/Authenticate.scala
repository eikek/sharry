package sharry.restserver.routes

import cats.data.*
import cats.effect.*
import cats.implicits.*

import sharry.backend.auth.*
import sharry.restserver.*

import org.http4s.*
import org.http4s.circe.CirceEntityEncoder.*
import org.http4s.dsl.Http4sDsl
import org.http4s.server.*
import org.typelevel.ci.CIString

object Authenticate {

  def authenticateRequest[F[_]: Async](
      auth: String => F[LoginResult]
  )(req: Request[F]): F[LoginResult] =
    CookieData.authenticator(req) match {
      case Right(str) => auth(str)
      case Left(_)    => LoginResult.invalidAuth.pure[F]
    }

  def of[F[_]: Async](S: Login[F], cfg: AuthConfig)(
      pf: PartialFunction[AuthedRequest[F, AuthToken], F[Response[F]]]
  ): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    val middleware = createAuthMiddleware(dsl, S, cfg)

    middleware(AuthedRoutes.of(pf))
  }

  def apply[F[_]: Async](S: Login[F], cfg: AuthConfig)(
      f: AuthToken => HttpRoutes[F]
  ): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    val middleware = createAuthMiddleware(dsl, S, cfg)

    middleware(AuthedRoutes(authReq => f(authReq.context).run(authReq.req)))
  }

  def alias[F[_]: Async](S: Login[F], cfg: AuthConfig)(
      f: AuthToken => HttpRoutes[F]
  ): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    import dsl._

    def aliasId(req: Request[F]): String =
      req.headers.get(CIString("sharry-alias")).map(_.head.value).getOrElse("")

    val authUser: Kleisli[F, Request[F], Either[String, AuthToken]] =
      Kleisli(r => S.loginAlias(cfg)(aliasId(r)).map(_.toEither))

    val onFailure: AuthedRoutes[String, F] =
      Kleisli(req => OptionT.liftF(Forbidden(req.context)))

    val middleware = AuthMiddleware(authUser, onFailure)

    middleware(AuthedRoutes(authReq => f(authReq.context).run(authReq.req)))
  }

  private def getUser[F[_]: Async](
      auth: String => F[LoginResult]
  ): Kleisli[F, Request[F], Either[String, AuthToken]] =
    Kleisli(r => authenticateRequest(auth)(r).map(_.toEither))

  private def createAuthMiddleware[F[_]: Async](
      dsl: Http4sDsl[F],
      S: Login[F],
      cfg: AuthConfig
  ): AuthMiddleware[F, AuthToken] = {
    import dsl._

    val authUser = getUser[F](S.loginSession(cfg))

    val onFailure: AuthedRoutes[String, F] =
      Kleisli(req => OptionT.liftF(Forbidden(req.context)))

    AuthMiddleware(authUser, onFailure)
  }
}
