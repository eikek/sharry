package sharry.restserver

import scala.concurrent.duration._

import cats.data.Kleisli
import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import sharry.backend.auth.AuthToken
import sharry.common.LenientUri
import sharry.common.syntax.all._
import sharry.restserver.http4s.EnvMiddleware
import sharry.restserver.routes._
import sharry.restserver.webapp._

import org.http4s._
import org.http4s.client.Client
import org.http4s.client.blaze.BlazeClientBuilder
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.Location
import org.http4s.implicits._
import org.http4s.server.Router
import org.http4s.server.blaze.BlazeServerBuilder
import org.http4s.server.middleware.Logger
import org.log4s.getLogger

object RestServer {
  private[this] val logger = getLogger

  def stream[F[_]: ConcurrentEffect](
      cfg: Config,
      pools: Pools
  )(implicit
      T: Timer[F],
      CS: ContextShift[F]
  ): Stream[F, Nothing] = {

    val templates = TemplateRoutes[F](pools.blocker, cfg)
    val app = for {
      restApp <- RestAppImpl.create[F](cfg, pools.connectEC, pools.blocker)
      _       <- Resource.eval(restApp.init)
      client  <- BlazeClientBuilder[F](pools.httpClientEC).resource

      httpApp = Router(
        "/api/v2/open/" -> openRoutes(cfg, client, restApp),
        "/api/v2/sec/" -> Authenticate(restApp.backend.login, cfg.backend.auth) { token =>
          securedRoutes(cfg, restApp, token)
        },
        "/api/v2/alias/" -> Authenticate.alias(restApp.backend.login, cfg.backend.auth) {
          token =>
            aliasRoutes[F](cfg, restApp, token)
        },
        "/api/v2/admin/" -> Authenticate(restApp.backend.login, cfg.backend.auth) {
          token =>
            if (token.account.admin) adminRoutes(cfg, restApp)
            else notFound[F](token)
        },
        "/api/doc"    -> templates.doc,
        "/app/assets" -> EnvMiddleware(WebjarRoutes.appRoutes[F](pools.blocker)),
        "/app"        -> EnvMiddleware(templates.app),
        "/sw.js"      -> EnvMiddleware(templates.serviceWorker),
        "/"           -> redirectTo("/app")
      ).orNotFound

      // With Middlewares in place
      finalHttpApp = Logger.httpApp(false, false)(httpApp)

    } yield finalHttpApp

    Stream
      .resource(app)
      .flatMap(httpApp =>
        BlazeServerBuilder[F](pools.restEC)
          .bindHttp(cfg.bind.port, cfg.bind.address)
          .withResponseHeaderTimeout(cfg.responseTimeout.toScala)
          .withIdleTimeout(cfg.responseTimeout.toScala + 30.seconds)
          .withHttpApp(httpApp)
          .withoutBanner
          .serve
      )

  }.drain

  def aliasRoutes[F[_]: Effect](
      cfg: Config,
      restApp: RestApp[F],
      token: AuthToken
  ): HttpRoutes[F] =
    Router(
      "upload" -> ShareUploadRoutes(
        restApp.backend,
        token,
        cfg,
        LenientUri.EmptyPath / "api" / "v2" / "alias" / "upload"
      ),
      "mail" -> NotifyRoutes(restApp.backend, token, cfg)
    )

  def securedRoutes[F[_]: Effect](
      cfg: Config,
      restApp: RestApp[F],
      token: AuthToken
  ): HttpRoutes[F] =
    Router(
      "auth"         -> LoginRoutes.session(restApp.backend.login, cfg),
      "settings"     -> SettingRoutes(restApp.backend, token),
      "alias-member" -> AliasMemberRoutes(restApp.backend, token),
      "alias"        -> AliasRoutes(restApp.backend, token),
      "share"        -> ShareRoutes(restApp.backend, token, cfg),
      "upload" -> ShareUploadRoutes(
        restApp.backend,
        token,
        cfg,
        LenientUri.EmptyPath / "api" / "v2" / "sec" / "upload"
      ),
      "mail" -> MailRoutes(restApp.backend, token, cfg)
    )

  def adminRoutes[F[_]: Effect](
      cfg: Config,
      restApp: RestApp[F]
  ): HttpRoutes[F] =
    Router(
      "signup"  -> RegisterRoutes(restApp.backend, cfg).genInvite,
      "account" -> AccountRoutes(restApp.backend)
    )

  def openRoutes[F[_]: ConcurrentEffect](
      cfg: Config,
      client: Client[F],
      restApp: RestApp[F]
  ): HttpRoutes[F] =
    Router(
      "info"   -> InfoRoutes(cfg),
      "auth"   -> LoginRoutes.login(restApp.backend, client, cfg),
      "signup" -> RegisterRoutes(restApp.backend, cfg).signup,
      "share"  -> OpenShareRoutes(restApp.backend, cfg)
    )

  def notFound[F[_]: Effect](token: AuthToken): HttpRoutes[F] =
    Kleisli(_ =>
      OptionT.liftF(
        logger
          .finfo[F](s"Non-admin '${token.account}' calling admin routes")
          .map(_ => Response.notFound[F])
      )
    )

  def redirectTo[F[_]: Effect](path: String): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case GET -> Root =>
      Response[F](
        Status.SeeOther,
        body = Stream.empty,
        headers = Headers.of(Location(Uri(path = path)))
      ).pure[F]
    }
  }
}
