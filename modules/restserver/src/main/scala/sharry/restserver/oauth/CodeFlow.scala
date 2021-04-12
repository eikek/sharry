package sharry.restserver.oauth

import cats.data.OptionT
import cats.effect.ConcurrentEffect
import cats.implicits._

import sharry.backend.auth.AuthConfig
import sharry.common.Ident
import sharry.common.syntax.all._

import io.circe.Json
import org.http4s.Method._
import org.http4s._
import org.http4s.circe.CirceEntityCodec._
import org.http4s.client.Client
import org.http4s.client.dsl.Http4sClientDsl
import org.http4s.client.middleware.RequestLogger
import org.http4s.client.middleware.ResponseLogger
import org.http4s.headers.Accept
import org.http4s.headers.Authorization
import org.log4s.getLogger

object CodeFlow {
  private[this] val logger = getLogger

  def apply[F[_]: ConcurrentEffect](
      client: Client[F]
  )(cfg: AuthConfig.OAuth, redirectUri: String, code: String): OptionT[F, Ident] = {

    val dsl = new Http4sClientDsl[F] {}
    val c   = logRequests[F](logResponses[F](client))

    for {
      _ <- OptionT.liftF(
        logger.fdebug[F](
          s"Obtaining access_token for provider ${cfg.id.id} and code $code"
        )
      )
      token <- codeToToken[F](c, dsl, cfg, redirectUri, code)
      _ <- OptionT.liftF(
        logger.fdebug[F](
          s"Obtaining user-info for provider ${cfg.id.id} and token $token"
        )
      )
      user <- tokenToUser[F](c, dsl, cfg, token)
    } yield user
  }

  private def codeToToken[F[_]: ConcurrentEffect](
      c: Client[F],
      dsl: Http4sClientDsl[F],
      cfg: AuthConfig.OAuth,
      redirectUri: String,
      code: String
  ): OptionT[F, String] = {
    import dsl._

    val req = POST(
      UrlForm(
        "client_id"     -> cfg.clientId,
        "client_secret" -> cfg.clientSecret,
        "code"          -> code,
        "grant_type"    -> "authorization_code",
        "redirect_uri"  -> redirectUri
      ),
      Uri.unsafeFromString(cfg.tokenUrl.asString)
    )

    OptionT(req.flatMap(c.run(_).use {
      case Status.Successful(r) =>
        val u1 = r.as[UrlForm].map(_.getFirst("access_token"))
        val u2 =
          r.as[Json].map(_.asObject.flatMap(_.apply("access_token")).flatMap(_.asString))
        u1.recoverWith(_ => u2).flatTap(at => logger.finfo(s"Got token: $at"))
      case r =>
        logger
          .ferror[F](s"Error obtaining access token '${r.status.code}' / ${r.as[String]}")
          .map(_ => None)
    }))
  }

  private def tokenToUser[F[_]: ConcurrentEffect](
      c: Client[F],
      dsl: Http4sClientDsl[F],
      cfg: AuthConfig.OAuth,
      token: String
  ): OptionT[F, Ident] = {
    import dsl._

    val req = GET(
      Uri.unsafeFromString(cfg.userUrl.asString),
      Authorization(Credentials.Token(AuthScheme.Bearer, token)),
      Accept(MediaType.application.json)
    )

    val resp: F[Option[Ident]] = req.flatMap(c.run(_).use {
      case Status.Successful(r) =>
        r.as[Json]
          .flatTap(j => logger.ftrace(s"user structure: ${j.noSpaces}"))
          .map(j => j.findAllByKey(cfg.userIdKey).find(_.isString).flatMap(_.asString))
          .map(_.map(normalizeUid))
          .flatTap(uid => logger.finfo(s"Got user id: $uid"))
      case r =>
        r.as[String]
          .flatMap(err =>
            logger.ferror(s"Cannot obtain user info: ${r.status.code} / ${err}")
          )
          .map(_ => None)

    })

    OptionT(resp)
  }

  private def normalizeUid(uid: String): Ident =
    Ident.unsafe(uid.filter(Ident.chars.contains))

  private def logRequests[F[_]: ConcurrentEffect](c: Client[F]): Client[F] =
    RequestLogger(
      logHeaders = true,
      logBody = true,
      logAction = Some((msg: String) => logger.ftrace[F](msg))
    )(c)

  private def logResponses[F[_]: ConcurrentEffect](c: Client[F]): Client[F] =
    ResponseLogger(
      logHeaders = true,
      logBody = true,
      logAction = Some((msg: String) => logger.ftrace[F](msg))
    )(c)

}
