package sharry.backend.auth

import scala.sys.process._

import cats.data.Kleisli
import cats.effect._
import cats.implicits._

import sharry.common._

import yamusca.implicits._
import yamusca.imports._

final class CommandAuth[F[_]: Async](
    cfg: AuthConfig,
    ops: AddAccount.AccountOps[F],
    runner: CommandAuth.RunCommand[F]
) {
  private val logger = sharry.logging.getLogger[F]

  def login: LoginModule[F] =
    LoginModule.whenEnabled(cfg.command.enabled)(
      Kleisli(up =>
        Ident.fromString(up.user) match {
          case Right(login) =>
            def okResult: F[LoginResult] =
              AddAccount(login, admin = false, ops)
                .flatMap(accId =>
                  AuthToken.user(accId, cfg.serverSecret).map(LoginResult.ok)
                )

            for {
              _ <- logger.debug(s"CommandAuth: starting login $up")
              res <- runCommand(up, cfg.command)
              resp <- if (res) okResult else LoginResult.invalidAuth.pure[F]
              _ <- logger.debug(s"CommandAuth: $up => $resp")
            } yield resp

          case Left(_) =>
            logger.debug(s"CommandAuth: failed.") *>
              LoginResult.invalidAuth.pure[F]
        }
      )
    )

  def runCommand(up: UserPassData, cfg: AuthConfig.Command): F[Boolean] =
    runner.exec(up, cfg)

  def withPosition: (Int, LoginModule[F]) = (cfg.command.order, login)

}

object CommandAuth {

  def apply[F[_]: Async](
      cfg: AuthConfig,
      ops: AddAccount.AccountOps[F],
      runner: RunCommand[F]
  ): CommandAuth[F] =
    new CommandAuth[F](cfg, ops, runner)

  trait RunCommand[F[_]] {
    def exec(up: UserPassData, cfg: AuthConfig.Command): F[Boolean]
  }

  object RunCommand {
    def apply[F[_]](f: (UserPassData, AuthConfig.Command) => F[Boolean]): RunCommand[F] =
      (up: UserPassData, cfg: AuthConfig.Command) => f(up, cfg)

    def systemProcess[F[_]: Sync]: RunCommand[F] =
      new RunCommand[F] {
        private val logger = sharry.logging.getLogger[F]

        def exec(up: UserPassData, cfg: AuthConfig.Command): F[Boolean] =
          Sync[F].delay {
            val prg = cfg.program.map(s =>
              mustache.parse(s) match {
                case Right(tpl) =>
                  up.render(tpl)
                case Left(err) =>
                  logger.warn(s"Error in command template '$s': $err")
                  s
              }
            )

            val result = Either.catchNonFatal(Process(prg).!)
            logger.debug(s"Result of external auth command: $result")
            result == Right(cfg.success)
          }
      }
  }
}
