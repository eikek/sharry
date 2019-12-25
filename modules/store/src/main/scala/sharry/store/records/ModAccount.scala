package sharry.store.records

import sharry.common._

case class ModAccount(
    state: AccountState,
    admin: Boolean,
    email: Option[String],
    password: Option[Password]
)
