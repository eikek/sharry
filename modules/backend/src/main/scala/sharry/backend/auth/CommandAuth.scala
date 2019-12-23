package sharry.backend.auth

import cats.data.Kleisli
import cats.effect._
import cats.implicits._
import org.log4s.getLogger
import yamusca.imports._
import yamusca.implicits._
import scala.sys.process._

import sharry.common._
import sharry.common.syntax.all._
import sharry.backend.account.OAccount

final class CommandAuth[F[_]: Effect](cfg: AuthConfig, oacc: OAccount[F]) {

  private[this] val logger = getLogger

  def login: LoginModule[F] =
    LoginModule.whenEnabled(cfg.command.enabled)(
      Kleisli(
        up =>
          Ident.fromString(up.user) match {
            case Right(login) =>
              def okResult: F[LoginResult] =
                HttpAuth
                  .addAccount(login, oacc)
                  .flatMap(
                    accId => AuthToken.user(accId, cfg.serverSecret).map(LoginResult.ok)
                  )

              for {
                _    <- logger.fdebug(s"CommandAuth: starting login $up")
                res  <- runCommand(up, cfg.command)
                resp <- if (res) okResult else LoginResult.invalidAuth.pure[F]
                _    <- logger.fdebug(s"CommandAuth: $up => $resp")
              } yield resp

            case Left(err) =>
              logger.fdebug(s"CommandAuth: failed.") *>
                LoginResult.invalidAuth.pure[F]
          }
      )
    )

  def runCommand(up: UserPassData, cfg: AuthConfig.Command): F[Boolean] = Effect[F].delay {
    val prg = cfg.program.
      map(s => mustache.parse(s) match {
        case Right(tpl) =>
          up.render(tpl)
        case Left(err) =>
          logger.warn(s"Error in command template '$s': $err")
          s
      })

    val result = Either.catchNonFatal(Process(prg).!)
    logger.debug(s"Result of external auth command: $result")
    result == Right(cfg.success)
  }

  def withPosition: (Int, LoginModule[F]) = (cfg.command.order, login)

}

object CommandAuth {

  def apply[F[_]: Effect](cfg: AuthConfig, oacc: OAccount[F]): CommandAuth[F] =
    new CommandAuth[F](cfg, oacc)
}
