package sharry.backend.auth

import cats.data.Kleisli
import cats.effect._
import cats.implicits._
import sharry.common._
import sharry.backend.account.{NewAccount, OAccount}
import sharry.store.records.RAccount

object AddAccount {

  case class AccountOps[F[_]](
      createIfMissing: Kleisli[F, NewAccount, RAccount],
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
      newAcc <- NewAccount.create[F](
        user,
        AccountSource.extern,
        AccountState.Active,
        Password.empty,
        None,
        false
      )
      id <-
        ops
          .createIfMissing(newAcc)
          .map(acc => acc.accountId(None))
          .flatTap(accId => ops.updateStats(accId))

    } yield id
}
