package sharry.backend.auth

import cats.data.Kleisli
import cats.effect._
import cats.implicits._
import org.log4s.getLogger

import sharry.common._
import sharry.common.syntax.all._
import sharry.backend.account.OAccount
import java.{util => ju}
import java.nio.charset.StandardCharsets
import java.net.HttpURLConnection

final class HttpBasicAuth[F[_]: Effect](cfg: AuthConfig, oacc: OAccount[F]) {

  private[this] val logger = getLogger

  def login: LoginModule[F] =
    LoginModule.whenEnabled(cfg.httpBasic.enabled)(
      Kleisli(up =>
        Ident.fromString(up.user) match {
          case Right(login) =>
            def okResult: F[LoginResult] =
              HttpAuth
                .addAccount(login, oacc)
                .flatMap(accId =>
                  AuthToken.user(accId, cfg.serverSecret).map(LoginResult.ok)
                )

            for {
              _    <- logger.fdebug(s"HttpBasicAuth: starting login $up")
              res  <- executeReq(up, cfg.httpBasic)
              resp <- if (res) okResult else LoginResult.invalidAuth.pure[F]
              _    <- logger.fdebug(s"HttpBasicAuth: $up => $resp")
            } yield resp

          case Left(err) =>
            logger.fdebug(s"HttpBasicAuth: failed.") *>
              LoginResult.invalidAuth.pure[F]
        }
      )
    )

  private def executeReq(up: UserPassData, cfg: AuthConfig.HttpBasic): F[Boolean] = {
    val header = ju.Base64.getEncoder
      .encodeToString(s"${up.user}:${up.pass.pass}".getBytes(StandardCharsets.UTF_8))

    cfg.url.open match {
      case Right(res) =>
        res.use(conn =>
          Effect[F].delay {
            conn.setRequestProperty("Authorization", s"Basic $header")
            conn.setRequestMethod(cfg.method)
            conn.connect()

            val code = conn.asInstanceOf[HttpURLConnection].getResponseCode()
            code >= 200 && code <= 299
          }
        )

      case Left(err) =>
        logger
          .fwarn(s"Invalid url for http-basic-auth '${cfg.url.asString}': $err")
          .map(_ => false)
    }
  }

  def withPosition: (Int, LoginModule[F]) = (cfg.httpBasic.order, login)

}

object HttpBasicAuth {

  def apply[F[_]: Effect](cfg: AuthConfig, oacc: OAccount[F]): HttpBasicAuth[F] =
    new HttpBasicAuth[F](cfg, oacc)

}
