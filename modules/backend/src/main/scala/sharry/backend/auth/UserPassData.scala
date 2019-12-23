package sharry.backend.auth
import sharry.common.Password

import yamusca.imports._
import yamusca.implicits._
import sharry.backend.mustache.YamuscaCommon._

case class UserPassData(user: String, pass: Password) {}

object UserPassData {

  implicit val yamuscaConverter: ValueConverter[UserPassData] =
    ValueConverter.deriveConverter[UserPassData]

}
