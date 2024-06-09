package sharry.backend.auth

import java.nio.charset.StandardCharsets
import java.util as ju

import cats.data.Kleisli
import cats.effect.*
import cats.implicits.*

import sharry.common.*

final class HttpBasicAuth[F[_]: Async](
    cfg: AuthConfig,
    ops: AddAccount.AccountOps[F],
    runner: HttpBasicAuth.RunRequest[F]
) {

  private val logger = sharry.logging.getLogger[F]

  def login: LoginModule[F] =
    LoginModule.whenEnabled(cfg.httpBasic.enabled)(
      Kleisli(up =>
        Ident.fromString(up.user) match {
          case Right(login) =>
            def okResult: F[LoginResult] =
              AddAccount(login, admin = false, ops)
                .flatMap(accId =>
                  AuthToken.user(accId, cfg.serverSecret).map(LoginResult.ok)
                )

            for {
              _ <- logger.debug(s"HttpBasicAuth: starting login $up")
              res <- executeReq(up, cfg.httpBasic)
              resp <- if (res) okResult else LoginResult.invalidAuth.pure[F]
              _ <- logger.debug(s"HttpBasicAuth: $up => $resp")
            } yield resp

          case Left(_) =>
            logger.debug(s"HttpBasicAuth: failed.") *>
              LoginResult.invalidAuth.pure[F]
        }
      )
    )

  private def executeReq(up: UserPassData, cfg: AuthConfig.HttpBasic): F[Boolean] =
    runner.exec(up, cfg)

  def withPosition: (Int, LoginModule[F]) = (cfg.httpBasic.order, login)

}

object HttpBasicAuth {

  def apply[F[_]: Async](
      cfg: AuthConfig,
      ops: AddAccount.AccountOps[F],
      runner: RunRequest[F]
  ): HttpBasicAuth[F] =
    new HttpBasicAuth[F](cfg, ops, runner)

  trait RunRequest[F[_]] {
    def exec(up: UserPassData, cfg: AuthConfig.HttpBasic): F[Boolean]
  }

  object RunRequest {
    def apply[F[_]](
        f: (UserPassData, AuthConfig.HttpBasic) => F[Boolean]
    ): RunRequest[F] =
      (up: UserPassData, cfg: AuthConfig.HttpBasic) => f(up, cfg)

    def javaConn[F[_]: Sync] = {
      val logger = sharry.logging.getLogger[F]
      RunRequest { (up, cfg) =>
        val header = ju.Base64.getEncoder
          .encodeToString(s"${up.user}:${up.pass.pass}".getBytes(StandardCharsets.UTF_8))

        cfg.url.open match {
          case Right(res) =>
            res.use(conn =>
              Sync[F].delay {
                conn.setRequestProperty("Authorization", s"Basic $header")
                conn.setRequestMethod(cfg.method)
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
