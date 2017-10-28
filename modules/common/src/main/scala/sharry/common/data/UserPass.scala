package sharry.common.data

import io.circe._, io.circe.generic.semiauto._

/** Tuple used for authenticating */
case class UserPass(login: String, pass: String)

object UserPass {
  implicit val _userPassDec: Decoder[UserPass] = deriveDecoder[UserPass]
  implicit val _userPassEnc: Encoder[UserPass] = deriveEncoder[UserPass]
}
