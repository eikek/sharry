package sharry.common.data

import io.circe._, io.circe.generic.semiauto._

case class UploadUpdate(name: String)

object UploadUpdate {
  implicit val _uploadUpdateDec: Decoder[UploadUpdate] = deriveDecoder[UploadUpdate]
  implicit val _uploadUpdateEnc: Encoder[UploadUpdate] = deriveEncoder[UploadUpdate]

}
