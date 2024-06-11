package sharry.backend.account

import cats.effect.Sync
import cats.implicits.*

import sharry.common.*

case class NewAccount(
    id: Ident,
    login: Ident,
    source: AccountSource,
    state: AccountState = AccountState.Active,
    password: Password = Password.empty,
    email: Option[String] = None,
    admin: Boolean = false
) {

  def validate: Either[String, NewAccount] =
    if (id.isEmpty) Left("An id is required")
    else if (login.isEmpty) Left("A login name is required")
    else Right(this)
}

object NewAccount {

  def create[F[_]: Sync](
      login: Ident,
      source: AccountSource,
      state: AccountState = AccountState.Active,
      password: Password = Password.empty,
      email: Option[String] = None,
      admin: Boolean = false
  ): F[NewAccount] =
    for {
      id <- Ident.randomId[F]
    } yield NewAccount(id, login, source, state, password, email, admin)

}
