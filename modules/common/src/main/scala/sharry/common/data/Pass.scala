package sharry.common.data

import io.circe._, io.circe.generic.semiauto._

case class Pass(password: String)

object Pass {
  implicit val jsonDecoder: Decoder[Pass] = deriveDecoder[Pass]
}
