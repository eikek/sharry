package sharry.backend.auth

import cats.data.Kleisli
import cats.data.OptionT
import cats.effect._
import cats.implicits._

import sharry.backend.account.OAccount
import sharry.common.Ident
import sharry.common.syntax.all._

import org.log4s._

trait Login[F[_]] {

  def loginSession(config: AuthConfig)(sessionKey: String): F[LoginResult]

  def loginUserPass(config: AuthConfig)(up: UserPassData): F[LoginResult]

  def loginAlias(config: AuthConfig)(alias: String): F[LoginResult]
}

object Login {
  private[this] val logger = getLogger

  def apply[F[_]: Effect](oacc: OAccount[F]): Resource[F, Login[F]] =
    Resource.pure[F, Login[F]](new Login[F] {

      def loginSession(config: AuthConfig)(sessionKey: String): F[LoginResult] =
        AuthToken.fromString(sessionKey) match {
          case Right(at) =>
            if (at.sigInvalid(config.serverSecret)) LoginResult.invalidAuth.pure[F]
            else if (at.isExpired(config.sessionValid)) LoginResult.invalidTime.pure[F]
            else LoginResult.ok(at).pure[F]
          case Left(_) =>
            LoginResult.invalidAuth.pure[F]
        }

      def loginUserPass(config: AuthConfig)(up: UserPassData): F[LoginResult] =
        logger.fdebug(s"Trying to login ${up}") *>
          createLoginModule[F](config, oacc).run(up)

      def loginAlias(config: AuthConfig)(alias: String): F[LoginResult] =
        (for {
          aliasId <-
            OptionT
              .fromOption[F](Ident.fromString(alias).toOption.filter(_ != Ident.empty))
          acc <- oacc.findByAlias(aliasId)
          tok <- OptionT.liftF(
            AuthToken
              .user(acc.accountId(Some(aliasId)).copy(admin = false), config.serverSecret)
          )
          res = LoginResult.ok(tok)
        } yield res).getOrElse(LoginResult.invalidAuth)

    })

  def createLoginModule[F[_]: Effect](
      cfg: AuthConfig,
      account: OAccount[F]
  ): Kleisli[F, UserPassData, LoginResult] = {
    val ops = AddAccount.AccountOps.from(account)
    val modules = List(
      FixedAuth[F](cfg, account).withPosition,
      InternalAuth[F](cfg, account).withPosition,
      HttpBasicAuth[F](cfg, ops, HttpBasicAuth.RunRequest.javaConn[F]).withPosition,
      HttpAuth[F](cfg, ops, HttpAuth.RunRequest.javaConn[F]).withPosition,
      CommandAuth[F](cfg, ops, CommandAuth.RunCommand.systemProcess[F]).withPosition
    ).sortBy(_._1).map(_._2)

    LoginModule.combine[F](modules: _*)
  }

}
