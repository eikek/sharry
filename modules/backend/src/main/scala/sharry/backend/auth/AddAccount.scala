package sharry.backend.auth

import cats.effect._
import cats.implicits._
import sharry.common._
import sharry.backend.account.{NewAccount, OAccount}
import cats.data.Kleisli

object AddAccount {

  case class AccountOps[F[_]](
      createIfMissing: Kleisli[F, NewAccount, Ident],
      updateStats: Kleisli[F, AccountId, Unit]
  )

  object AccountOps {
    def from[F[_]](oacc: OAccount[F]): AccountOps[F] =
      AccountOps(Kleisli(oacc.createIfMissing), Kleisli(oacc.updateLoginStats))
  }

  def apply[F[_]: Sync](
      user: Ident,
      ops: AccountOps[F]
  ): F[AccountId] =
    for {
      acc <- NewAccount.create[F](
        user,
        AccountSource.extern,
        AccountState.Active,
        Password.empty,
        None,
        false
      )
      id <-
        ops
          .createIfMissing(acc)
          .map(id => AccountId(id, user, acc.admin, None))
          .flatTap(accId => ops.updateStats(accId))

    } yield id
}
