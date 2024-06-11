package sharry.backend.auth

import java.nio.charset.StandardCharsets

import cats.data.Kleisli
import cats.effect.*
import cats.implicits.*

import sharry.common.*

import yamusca.implicits.*
import yamusca.imports.*

final class HttpAuth[F[_]: Async](
    cfg: AuthConfig,
    ops: AddAccount.AccountOps[F],
    runner: HttpAuth.RunRequest[F]
) {

  private val logger = sharry.logging.getLogger[F]

  def login: LoginModule[F] =
    LoginModule.whenEnabled(cfg.http.enabled)(
      Kleisli(up =>
        Ident.fromString(up.user) match {
          case Right(login) =>
            def okResult: F[LoginResult] =
              AddAccount(login, admin = false, ops)
                .flatMap(accId =>
                  AuthToken.user(accId, cfg.serverSecret).map(LoginResult.ok)
                )

            for {
              _ <- logger.debug(s"HttpAuth: starting login $up")
              res <- executeReq(up, cfg.http)
              resp <- if (res) okResult else LoginResult.invalidAuth.pure[F]
              _ <- logger.debug(s"HttpAuth: $up => $resp")
            } yield resp

          case Left(_) =>
            logger.debug(s"HttpAuth: failed.") *>
              LoginResult.invalidAuth.pure[F]
        }
      )
    )

  private def executeReq(up: UserPassData, cfg: AuthConfig.Http): F[Boolean] =
    runner.exec(up, cfg)

  def withPosition: (Int, LoginModule[F]) = (cfg.http.order, login)

}

object HttpAuth {

  def apply[F[_]: Async](
      cfg: AuthConfig,
      ops: AddAccount.AccountOps[F],
      runner: RunRequest[F]
  ): HttpAuth[F] =
    new HttpAuth[F](cfg, ops, runner)

  trait RunRequest[F[_]] {
    def exec(up: UserPassData, cfg: AuthConfig.Http): F[Boolean]
  }

  object RunRequest {

    def apply[F[_]](f: (UserPassData, AuthConfig.Http) => F[Boolean]): RunRequest[F] =
      (up: UserPassData, cfg: AuthConfig.Http) => f(up, cfg)

    def javaConn[F[_]: Sync]: RunRequest[F] = {
      val logger = sharry.logging.getLogger[F]
      apply { (up, cfg) =>
        val url =
          mustache
            .parse(cfg.url.asString)
            .leftMap(_.toString)
            .map(up.render)
            .flatMap(LenientUri.parse)

        url.flatMap(_.open) match {
          case Right(res) =>
            res.use(conn =>
              Sync[F].delay {
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
                  val outs = conn.getOutputStream
                  outs.write(body.getBytes(StandardCharsets.UTF_8))
                  outs.flush()
                  outs.close()
                }
                conn.connect()

                val code = conn.getResponseCode
                code >= 200 && code <= 299
              }
            )

          case Left(err) =>
            logger
              .warn(s"Invalid url for http-basic-auth '${cfg.url.asString}': $err")
              .map(_ => false)
        }
      }
    }
  }
}
