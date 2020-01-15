package sharry.restserver

import cats.data.Kleisli
import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream
import org.http4s._
import org.http4s.client.Client
import org.http4s.client.blaze.BlazeClientBuilder
import org.http4s.implicits._
import org.http4s.headers.Location
import org.http4s.server.Router
import org.http4s.server.blaze.BlazeServerBuilder
import org.http4s.server.middleware.Logger
import org.log4s.getLogger
import scala.concurrent.ExecutionContext

import sharry.common.syntax.all._
import sharry.backend.auth.AuthToken
import sharry.restserver.routes._
import sharry.restserver.webapp._

object RestServer {
  private[this] val logger = getLogger

  def stream[F[_]: ConcurrentEffect](
      cfg: Config,
      ec: ExecutionContext,
      connectEC: ExecutionContext,
      blocker: Blocker
  )(
      implicit T: Timer[F],
      CS: ContextShift[F]
  ): Stream[F, Nothing] = {

    val templates = TemplateRoutes[F](blocker, cfg)
    val app = for {
      restApp <- RestAppImpl.create[F](cfg, connectEC, blocker)
      _       <- Resource.liftF(restApp.init)
      client  <- BlazeClientBuilder[F](ec).resource

      httpApp = Router(
        "/api/v2/open/" -> openRoutes(cfg, client, restApp),
        "/api/v2/sec/" -> Authenticate(restApp.backend.login, cfg.backend.auth) { token =>
          securedRoutes(cfg, restApp, token)
        },
        "/api/v2/alias/" -> Authenticate.alias(restApp.backend.login, cfg.backend.auth) { token =>
          aliasRoutes[F](cfg, restApp, token)
        },
        "/api/v2/admin/" -> Authenticate(restApp.backend.login, cfg.backend.auth) { token =>
          if (token.account.admin) adminRoutes(cfg, restApp, token)
          else notFound[F](token)
        },
        "/api/doc"    -> templates.doc,
        "/app/assets" -> WebjarRoutes.appRoutes[F](blocker, cfg),
        "/app"        -> templates.app,
        "/"           -> redirectTo("/app")
      ).orNotFound

      // With Middlewares in place
      finalHttpApp = Logger.httpApp(false, false)(httpApp)

    } yield finalHttpApp

    Stream
      .resource(app)
      .flatMap(httpApp =>
        BlazeServerBuilder[F]
          .bindHttp(cfg.bind.port, cfg.bind.address)
          .withHttpApp(httpApp)
          .withoutBanner
          .serve
      )

  }.drain

  def aliasRoutes[F[_]: Effect](cfg: Config, restApp: RestApp[F], token: AuthToken): HttpRoutes[F] =
    Router(
      "upload" -> ShareUploadRoutes(
        restApp.backend,
        token,
        cfg,
        cfg.baseUrl / "api" / "v2" / "alias" / "upload"
      ),
      "mail" -> NotifyRoutes(restApp.backend, token, cfg)
    )

  def securedRoutes[F[_]: Effect](
      cfg: Config,
      restApp: RestApp[F],
      token: AuthToken
  ): HttpRoutes[F] =
    Router(
      "auth"     -> LoginRoutes.session(restApp.backend.login, cfg),
      "settings" -> SettingRoutes(restApp.backend, token, cfg),
      "alias"    -> AliasRoutes(restApp.backend, token, cfg),
      "share"    -> ShareRoutes(restApp.backend, token, cfg),
      "upload" -> ShareUploadRoutes(
        restApp.backend,
        token,
        cfg,
        cfg.baseUrl / "api" / "v2" / "sec" / "upload"
      ),
      "mail" -> MailRoutes(restApp.backend, token, cfg)
    )

  def adminRoutes[F[_]: Effect](cfg: Config, restApp: RestApp[F], token: AuthToken): HttpRoutes[F] =
    Router(
      "signup"  -> RegisterRoutes(restApp.backend, cfg).genInvite,
      "account" -> AccountRoutes(restApp.backend, cfg)
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
    Kleisli(req =>
      OptionT.liftF(
        logger
          .finfo[F](s"Non-admin '${token.account}' calling admin routes")
          .map(_ => Response.notFound[F])
      )
    )

  def redirectTo[F[_]: Effect](path: String): HttpRoutes[F] =
    Kleisli(req =>
      OptionT.pure(
        Response[F](
          Status.SeeOther,
          body = Stream.empty,
          headers = Headers.of(Location(Uri(path = path)))
        )
      )
    )
}
