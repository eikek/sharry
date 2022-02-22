package sharry.backend.auth
import sharry.backend.mustache.YamuscaCommon._
import sharry.common.Password

import yamusca.derive._
import yamusca.implicits._
import yamusca.imports._

case class UserPassData(user: String, pass: Password) {}

object UserPassData {

  implicit val yamuscaConverter: ValueConverter[UserPassData] =
    deriveValueConverter[UserPassData]

}
