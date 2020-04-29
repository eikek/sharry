package sharry.backend.auth

import cats.data.Kleisli
import cats.effect._
import cats.implicits._
import org.log4s.getLogger

import sharry.common._
import sharry.common.syntax.all._
import sharry.backend.account.OAccount
import sharry.backend.account.NewAccount
import yamusca.imports._
import yamusca.implicits._
import java.net.HttpURLConnection
import java.nio.charset.StandardCharsets

final class HttpAuth[F[_]: Effect](cfg: AuthConfig, oacc: OAccount[F]) {

  private[this] val logger = getLogger

  def login: LoginModule[F] =
    LoginModule.whenEnabled(cfg.http.enabled)(
      Kleisli(up =>
        Ident.fromString(up.user) match {
          case Right(login) =>
            def okResult: F[LoginResult] =
              HttpAuth
                .addAccount(login, oacc)
                .flatMap(accId => AuthToken.user(accId, cfg.serverSecret).map(LoginResult.ok))

            for {
              _    <- logger.fdebug(s"HttpAuth: starting login $up")
              res  <- executeReq(up, cfg.http)
              resp <- if (res) okResult else LoginResult.invalidAuth.pure[F]
              _    <- logger.fdebug(s"HttpAuth: $up => $resp")
            } yield resp

          case Left(err) =>
            logger.fdebug(s"HttpAuth: failed.") *>
              LoginResult.invalidAuth.pure[F]
        }
      )
    )

  private def executeReq(up: UserPassData, cfg: AuthConfig.Http): F[Boolean] = {
    val url =
      mustache.parse(cfg.url.asString).leftMap(_.toString).map(up.render).flatMap(LenientUri.parse)

    url.flatMap(_.open) match {
      case Right(res) =>
        res.use(conn =>
          Effect[F].delay {
            conn.setRequestMethod(cfg.method)
            if (cfg.method.equalsIgnoreCase("post")) {
              conn.setDoOutput(true)
              conn.setRequestProperty("Content-Type", cfg.contentType)

              val body = mustache.parse(cfg.body) match {
                case Right(tpl) =>
                  up.render(tpl)
                case Left(err) =>
                  logger.warn(s"Invalid mustache template for http body: $err")
                  cfg.body
              }
              val outs = conn.getOutputStream()
              outs.write(body.getBytes(StandardCharsets.UTF_8))
              outs.flush()
              outs.close()
            }
            conn.connect()

            val code = conn.asInstanceOf[HttpURLConnection].getResponseCode()
            code >= 200 && code <= 299
          }
        )

      case Left(err) =>
        logger.fwarn(s"Invalid url for http-basic-auth '${cfg.url.asString}': $err").map(_ => false)
    }
  }

  def withPosition: (Int, LoginModule[F]) = (cfg.http.order, login)

}

object HttpAuth {

  def apply[F[_]: Effect](cfg: AuthConfig, oacc: OAccount[F]): HttpAuth[F] =
    new HttpAuth[F](cfg, oacc)

  def addAccount[F[_]: Sync](user: Ident, oacc: OAccount[F]): F[AccountId] =
    for {
      acc <- NewAccount.create[F](
              user,
              AccountSource.extern,
              AccountState.Active,
              Password.empty,
              None,
              false
            )
      id <- oacc
             .createIfMissing(acc)
             .map(id => AccountId(id, user, true, None))
             .flatTap(accId => oacc.updateLoginStats(accId))

    } yield id

}
