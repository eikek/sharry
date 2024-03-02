package sharry.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import sharry.backend.BackendApp
import sharry.backend.account.NewAccount
import sharry.backend.auth._
import sharry.common._
import sharry.restapi.model._
import sharry.restserver._
import sharry.restserver.config.Config
import sharry.restserver.http4s.ClientRequestInfo
import sharry.restserver.oauth.{CodeFlow, StateParam}

import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.client.Client
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.Location
import org.typelevel.ci.CIString

object LoginRoutes {

  def login[F[_]: Async](
      S: BackendApp[F],
      client: Client[F],
      cfg: Config
  ): HttpRoutes[F] = {
    val logger = sharry.logging.getLogger[F]
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of[F] {
      case req @ POST -> Root / "login" =>
        for {
          up <- req.as[UserPass]
          res <- S.login.loginUserPass(cfg.backend.auth)(
            UserPassData(up.account, Password(up.password))
          )
          resp <- makeResponse(dsl, cfg, req, res, up.account)
        } yield resp

      case req @ POST -> Root / "proxy" =>
        val unameOpt =
          req.headers
            .get(CIString(cfg.backend.auth.proxy.userHeader))
            .map(_.head.value)
            .filter(_ => cfg.backend.auth.proxy.enabled)

        val email = cfg.backend.auth.proxy.emailHeader
          .map(CIString.apply)
          .flatMap(req.headers.get(_).map(_.head.value))

        def doLogin(userId: Ident) = for {
          newAcc <- NewAccount.create(userId, AccountSource.Extern, email = email)
          token <- finalizeLogin(cfg, S)(newAcc)
          resp <- makeResponse(dsl, cfg, req, LoginResult.ok(token), userId.id)
        } yield resp

        for {
          _ <-
            if (cfg.backend.auth.proxy.disabled)
              logger.info("Proxy authentication is disabled in the config!")
            else logger.debug(s"Use proxy authentication: user=$unameOpt, email=$email")

          resp <- unameOpt.map(Ident.apply) match {
            case None =>
              makeResponse(
                dsl,
                cfg,
                req,
                LoginResult.invalidAuth,
                unameOpt.getOrElse("<no-user-id>")
              )
            case Some(Left(err)) =>
              logger.error(s"Error reading username from header: $err") >>
                makeResponse(
                  dsl,
                  cfg,
                  req,
                  LoginResult.invalidAuth,
                  unameOpt.getOrElse("<no-user-id>")
                )
            case Some(Right(userId)) => doLogin(userId)
          }
        } yield resp

      case req @ GET -> Root / "oauth" / id =>
        findOAuthProvider(cfg, id) match {
          case Some(p) =>
            for {
              state <- StateParam.generate[F](cfg.backend.auth.serverSecret)
              uri = p.authorizeUrl
                .withQuery("client_id", p.clientId)
                .withQuery("scope", p.scope)
                .withQuery(
                  "redirect_uri",
                  redirectUri(cfg, req, p).asString
                )
                .withQuery("response_type", "code")
                .withQuery("state", state.asString)
              _ <- logger.debug(
                s"Redirecting to OAuth provider ${p.id.id}: ${uri.asString}"
              )
              resp <- Found(Location(Uri.unsafeFromString(uri.asString)))
            } yield resp

          case None =>
            logger.debug(s"No oauth provider found with id '$id'") *> BadRequest()
        }

      case req @ GET -> Root / "oauth" / id / "resume" =>
        val prov = OptionT.fromOption[F](findOAuthProvider(cfg, id))
        val code = OptionT.fromOption[F](req.params.get("code"))
        val stateParamValid = req.params
          .get("state")
          .exists(state =>
            StateParam.isValidStateParam(state, cfg.backend.auth.serverSecret)
          )

        val userId = for {
          _ <-
            if (stateParamValid) OptionT.pure[F](())
            else
              OptionT(
                logger
                  .warn(s"Invalid state parameter returned form IDP!")
                  .as(Option.empty[Unit])
              )
          p <- prov
          c <- code
          u <- CodeFlow(client)(p, redirectUri(cfg, req, p).asString, c)
          newAcc <- OptionT.liftF(
            NewAccount.create(
              u.id ++ Ident.atSign ++ p.id,
              AccountSource.OAuth(p.id.id),
              email = u.email
            )
          )
          token <- OptionT.liftF(finalizeLogin(cfg, S)(newAcc))
        } yield token

        val uri = getBaseUrl(cfg, req).withQuery("oauth", "1") / "app" / "login"
        val location = Location(Uri.unsafeFromString(uri.asString))
        userId.value.flatMap {
          case Some(t) =>
            TemporaryRedirect(location)
              .map(_.addCookie(CookieData(t).asCookie(getBaseUrl(cfg, req))))
          case None => TemporaryRedirect(location)
        }
    }
  }

  private def finalizeLogin[F[_]: Async](cfg: Config, S: BackendApp[F])(
      newAcc: NewAccount
  ) =
    for {
      acc <- S.account.createIfMissing(newAcc)
      accId = acc.accountId(None)
      _ <- S.account.updateLoginStats(accId)
      token <- AuthToken.user[F](accId, cfg.backend.auth.serverSecret)
    } yield token

  private def redirectUri[F[_]](
      cfg: Config,
      req: Request[F],
      prov: AuthConfig.OAuth
  ): LenientUri =
    getBaseUrl(
      cfg,
      req
    ) / "api" / "v2" / "open" / "auth" / "oauth" / prov.id.id / "resume"

  private def findOAuthProvider(cfg: Config, id: String): Option[AuthConfig.OAuth] =
    cfg.backend.auth.oauth.filter(_.enabled).find(_.id.id == id)

  def session[F[_]: Async](S: Login[F], cfg: Config): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of[F] {
      case req @ POST -> Root / "session" =>
        Authenticate
          .authenticateRequest(S.loginSession(cfg.backend.auth))(req)
          .flatMap(res =>
            makeResponse(dsl, cfg, req, res, "unknown due to session login")
          )

      case req @ POST -> Root / "logout" =>
        Ok().map(_.addCookie(CookieData.deleteCookie(getBaseUrl(cfg, req))))
    }
  }

  private def getBaseUrl[F[_]](cfg: Config, req: Request[F]): LenientUri =
    ClientRequestInfo.getBaseUrl(cfg, req)

  def makeResponse[F[_]: Async](
      dsl: Http4sDsl[F],
      cfg: Config,
      req: Request[F],
      res: LoginResult,
      accountName: String
  ): F[Response[F]] = {
    import dsl._
    val logger = sharry.logging.getLogger[F]

    res match {
      case LoginResult.Ok(token) =>
        for {
          cd <-
            AuthToken
              .user(token.account, cfg.backend.auth.serverSecret)
              .map(CookieData.apply)
          resp <- Ok(
            AuthResult(
              token.account.id,
              token.account.userLogin,
              token.account.admin,
              success = true,
              "Login successful",
              Some(cd.asString),
              cfg.backend.auth.sessionValid.millis
            )
          ).map(_.addCookie(cd.asCookie(getBaseUrl(cfg, req))))
        } yield resp
      case _ =>
        logger.info(
          s"Authentication attempt failure for username $accountName from ip ${req.from.map(_.toInetAddress.getHostAddress).getOrElse("Unknown ip")}"
        ) *>
          Ok(
            AuthResult(
              Ident.empty,
              Ident.empty,
              admin = false,
              success = false,
              "Login failed.",
              None,
              0L
            )
          )
    }
  }

}
