package sharry.common.data

import io.circe._, io.circe.generic.semiauto._

case class AliasUpdate(id: String, login: String, name: String, validity: String, enable: Boolean)

object AliasUpdate {
  implicit val _jsonDecoder: Decoder[AliasUpdate] = deriveDecoder[AliasUpdate]
  implicit val _jsonEncoder: Encoder[AliasUpdate] = deriveEncoder[AliasUpdate]
}
