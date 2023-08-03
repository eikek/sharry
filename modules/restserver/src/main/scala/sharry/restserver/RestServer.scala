package sharry.restserver

import cats.data.{Kleisli, OptionT}
import cats.effect._
import cats.syntax.all._
import fs2.{Pure, Stream}
import fs2.io.net.Network
import fs2.io.file.Files

import sharry.backend.auth.AuthToken
import sharry.common.LenientUri
import sharry.logging.Logger
import sharry.restserver.config.Config
import sharry.restserver.http4s.EnvMiddleware
import sharry.restserver.routes._
import sharry.restserver.webapp._

import org.http4s._
import org.http4s.client.Client
import org.http4s.dsl.Http4sDsl
import org.http4s.ember.client.EmberClientBuilder
import org.http4s.ember.server.EmberServerBuilder
import org.http4s.headers.{Location, `Content-Length`, `Content-Type`}
import org.http4s.server.Router
import org.http4s.server.middleware.{Logger => Http4sLogger}

object RestServer {
  def stream[F[_]: Async: Files: Network](cfg: Config, pools: Pools): Stream[F, Nothing] = {
    implicit val logger = sharry.logging.getLogger[F]

    val server = httpApp(cfg, pools).flatMap(httpServer(cfg, _))
    Stream
      .resource(server)
      .evalTap(s => logger.info(s"Started http server at ${s.baseUri}"))
      .flatMap(_ => Stream.never)
  }

  def httpServer[F[_]: Async: Network: Logger](cfg: Config, app: HttpApp[F]) =
    EmberServerBuilder
      .default[F]
      .withHost(cfg.bind.address)
      .withPort(cfg.bind.port)
      .withErrorHandler { case ex =>
        Logger[F]
          .error(ex)("Error processing request!")
          .as(internalError(ex.getMessage).covary[F])
      }
      .withHttpApp(app)
      .build

  def httpApp[F[_]: Async: Files: Network: Logger](cfg: Config, pools: Pools): Resource[F, HttpApp[F]] = {
    val templates = TemplateRoutes[F](cfg)
    for {
      restApp <- RestAppImpl.create[F](cfg, pools.connectEC)
      client <- EmberClientBuilder.default[F].build

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
        "/api/doc" -> templates.doc,
        "/app/assets" -> EnvMiddleware(WebjarRoutes.appRoutes[F]),
        "/app" -> EnvMiddleware(templates.app),
        "/sw.js" -> EnvMiddleware(templates.serviceWorker),
        "/" -> redirectTo("/app")
      ).orNotFound

      // With Middlewares in place
      finalHttpApp = Http4sLogger.httpApp(false, false)(httpApp)

    } yield finalHttpApp
  }

  def aliasRoutes[F[_]: Async](
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

  def securedRoutes[F[_]: Async](
      cfg: Config,
      restApp: RestApp[F],
      token: AuthToken
  )(implicit logger: Logger[F]): HttpRoutes[F] =
    Router(
      "auth" -> LoginRoutes.session(restApp.backend.login, cfg),
      "settings" -> SettingRoutes(restApp.backend, token),
      "alias-member" ->
        (if (cfg.aliasMemberEnabled) AliasMemberRoutes(restApp.backend, token)
         else notFound[F](token)),
      "alias" -> AliasRoutes(restApp.backend, token),
      "share" -> ShareRoutes(restApp.backend, token, cfg),
      "upload" -> ShareUploadRoutes(
        restApp.backend,
        token,
        cfg,
        LenientUri.EmptyPath / "api" / "v2" / "sec" / "upload"
      ),
      "mail" -> MailRoutes(restApp.backend, token, cfg)
    )

  def adminRoutes[F[_]: Async](
      cfg: Config,
      restApp: RestApp[F]
  ): HttpRoutes[F] =
    Router(
      "signup" -> RegisterRoutes(restApp.backend, cfg).genInvite,
      "account" -> AccountRoutes(restApp.backend)
    )

  def openRoutes[F[_]: Async](
      cfg: Config,
      client: Client[F],
      restApp: RestApp[F]
  ): HttpRoutes[F] =
    Router(
      "info" -> InfoRoutes(cfg),
      "auth" -> LoginRoutes.login(restApp.backend, client, cfg),
      "signup" -> RegisterRoutes(restApp.backend, cfg).signup,
      "share" -> OpenShareRoutes(restApp.backend, cfg)
    )

  def notFound[F[_]: Async](token: AuthToken)(implicit logger: Logger[F]): HttpRoutes[F] =
    Kleisli(_ =>
      OptionT.liftF(
        logger
          .info(s"Non-admin '${token.account}' calling admin routes")
          .map(_ => Response.notFound[F])
      )
    )

  private def internalError(msg: String): Response[Pure] =
    Response(
      status = Status.InternalServerError,
      body = Stream.emit(s"Internal Error: $msg").through(fs2.text.utf8.encode),
      headers = Headers(
        `Content-Type`(MediaType.text.plain, Charset.`UTF-8`),
        `Content-Length`.unsafeFromLong(16L + msg.length)
      )
    )

  def redirectTo[F[_]: Async](path: String): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case GET -> Root =>
      Response[F](
        Status.SeeOther,
        body = Stream.empty,
        headers = Headers(Location(Uri(path = Uri.Path.unsafeFromString(path))))
      ).pure[F]
    }
  }
}
