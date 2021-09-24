package sharry.backend.auth

import cats.Applicative
import cats.Monad
import cats.data.Kleisli
import cats.data.OptionT
import cats.effect.Sync
import cats.implicits._

import sharry.backend.account.OAccount
import sharry.common._

object LoginModule {

  def apply[F[_]](run: UserPassData => F[Option[LoginResult]]): LoginModule[F] =
    Kleisli(run)

  def whenEnabled[F[_]: Applicative](
      enabled: Boolean
  )(f: Kleisli[F, UserPassData, LoginResult]): LoginModule[F] =
    if (enabled) f.map(_.some) else loginEmpty[F]

  def loginEmpty[F[_]: Applicative]: LoginModule[F] =
    LoginModule(_ => (None: Option[LoginResult]).pure[F])

  def loginPure[F[_]: Applicative](r: LoginResult): LoginModule[F] =
    LoginModule(_ => (Some(r): Option[LoginResult]).pure[F])

  def finalResult(r: Option[LoginResult]): LoginResult =
    r.getOrElse(LoginResult.invalidAuth)

  def combine[F[_]: Monad](ms: LoginModule[F]*): Kleisli[F, UserPassData, LoginResult] = {
    val module: LoginModule[F] =
      ms.foldLeft(loginEmpty[F]) { (result, el) =>
        result.flatMap(_.map(loginPure[F]).getOrElse(el))
      }

    module.map(finalResult)
  }

  def enabledState[F[_]: Sync](enable: Boolean, op: OAccount[F], src: AccountSource)(
      f: Kleisli[F, UserPassData, LoginResult]
  ): LoginModule[F] =
    if (!enable) loginEmpty[F]
    else
      LoginModule { up =>
        Ident.fromString(up.user) match {
          case Right(login) =>
            (for {
              _ <- OptionT(op.findByLogin(login)).filter(_.source == src)
              res <- OptionT.liftF(f.run(up))
            } yield res).value
          case Left(_) =>
            OptionT.some[F](LoginResult.invalidAuth).value
        }
      }
}
