package sharry.store.records

import sharry.common.*

case class ModAccount(
    state: AccountState,
    admin: Boolean,
    email: Option[String],
    password: Option[Password]
)
