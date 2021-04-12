package sharry.backend.auth
import sharry.backend.mustache.YamuscaCommon._
import sharry.common.Password

import yamusca.implicits._
import yamusca.imports._

case class UserPassData(user: String, pass: Password) {}

object UserPassData {

  implicit val yamuscaConverter: ValueConverter[UserPassData] =
    ValueConverter.deriveConverter[UserPassData]

}
