package sharry.backend.auth
import sharry.backend.mustache.YamuscaCommon.*
import sharry.common.Password

import yamusca.derive.*
import yamusca.implicits.*
import yamusca.imports.*

case class UserPassData(user: String, pass: Password) {}

object UserPassData {

  implicit val yamuscaConverter: ValueConverter[UserPassData] =
    deriveValueConverter[UserPassData]

}
