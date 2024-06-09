package sharry.restserver.oauth

import cats.data.OptionT
import cats.effect.*
import cats.implicits.*

import sharry.backend.auth.AuthConfig
import sharry.common.Ident
import sharry.logging.Logger

import io.circe.Json
import org.http4s.*
import org.http4s.Method.*
import org.http4s.circe.CirceEntityCodec.*
import org.http4s.client.Client
import org.http4s.client.dsl.Http4sClientDsl
import org.http4s.client.middleware.RequestLogger
import org.http4s.client.middleware.ResponseLogger
import org.http4s.headers.Accept
import org.http4s.headers.Authorization

object CodeFlow {
  case class UserInfo(id: Ident, email: Option[String])

  def apply[F[_]: Async](
      client: Client[F]
  )(cfg: AuthConfig.OAuth, redirectUri: String, code: String): OptionT[F, UserInfo] = {
    val logger = sharry.logging.getLogger[F]
    val dsl = new Http4sClientDsl[F] {}
    val c = logRequestResponses[F](client, logger)

    for {
      _ <- OptionT.liftF(
        logger.debug(
          s"Obtaining access_token for provider ${cfg.id.id} and code $code"
        )
      )
      token <- codeToToken[F](c, dsl, cfg, redirectUri, code)
      _ <- OptionT.liftF(
        logger.debug(
          s"Obtaining user-info for provider ${cfg.id.id} and token $token"
        )
      )
      user <- tokenToUser[F](c, dsl, cfg, token)
    } yield user
  }

  private def codeToToken[F[_]: Async](
      c: Client[F],
      dsl: Http4sClientDsl[F],
      cfg: AuthConfig.OAuth,
      redirectUri: String,
      code: String
  ): OptionT[F, String] = {
    import dsl._
    val logger = sharry.logging.getLogger[F]
    val req = POST(
      UrlForm(
        "client_id" -> cfg.clientId,
        "client_secret" -> cfg.clientSecret,
        "code" -> code,
        "grant_type" -> "authorization_code",
        "redirect_uri" -> redirectUri
      ),
      Uri.unsafeFromString(cfg.tokenUrl.asString)
    )

    OptionT(c.run(req).use {
      case Status.Successful(r) =>
        val u1 = r.as[UrlForm].map(_.getFirst("access_token"))
        val u2 =
          r.as[Json].map(_.asObject.flatMap(_.apply("access_token")).flatMap(_.asString))
        u1.recoverWith(_ => u2).flatTap(at => logger.info(s"Got token: $at"))
      case r =>
        logger
          .error(s"Error obtaining access token '${r.status.code}' / ${r.as[String]}")
          .map(_ => None)
    })
  }

  private def tokenToUser[F[_]: Async](
      c: Client[F],
      dsl: Http4sClientDsl[F],
      cfg: AuthConfig.OAuth,
      token: String
  ): OptionT[F, UserInfo] = {
    import dsl._
    val logger = sharry.logging.getLogger[F]
    val req = GET(
      Uri.unsafeFromString(cfg.userUrl.asString),
      Authorization(Credentials.Token(AuthScheme.Bearer, token)),
      Accept(MediaType.application.json)
    )

    val resp: F[Option[UserInfo]] = c.run(req).use {
      case Status.Successful(r) =>
        r.as[Json]
          .flatTap(j => logger.trace(s"user structure: ${j.noSpaces}"))
          .map(decode(cfg))
          .flatTap(uid => logger.info(s"Got user id: $uid"))
      case r =>
        r.as[String]
          .flatMap(err =>
            logger.error(s"Cannot obtain user info: ${r.status.code} / $err")
          )
          .map(_ => None)
    }

    OptionT(resp)
  }

  private def decode(cfg: AuthConfig.OAuth)(json: Json): Option[UserInfo] =
    for {
      id <- json.findAllByKey(cfg.userIdKey).find(_.isString).flatMap(_.asString)
      email = cfg.userEmailKey.toList
        .flatMap(json.findAllByKey)
        .find(_.isString)
        .flatMap(_.asString)
        .map(_.trim)
        .find(_.nonEmpty)
    } yield UserInfo(normalizeUid(id), email)

  private def normalizeUid(uid: String): Ident =
    Ident.unsafe(uid.filter(Ident.chars.contains))

  private def logRequestResponses[F[_]: Async](
      c: Client[F],
      logger: Logger[F]
  ): Client[F] = {
    val lreq = RequestLogger(
      logHeaders = true,
      logBody = true,
      logAction = Some((msg: String) => logger.trace(msg))
    )

    val lres = ResponseLogger(
      logHeaders = true,
      logBody = true,
      logAction = Some((msg: String) => logger.trace(msg))
    )

    lreq.andThen(lres)(c)
  }
}
