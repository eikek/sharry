package sharry.backend.mail

import sharry.backend.mail.NotifyData.AccountInfo
import sharry.common._

final case class NotifyData(
    aliasId: Ident,
    aliasName: String,
    users: List[AccountInfo]
)

object NotifyData {

  final case class AccountInfo(login: Ident, email: String)
}
