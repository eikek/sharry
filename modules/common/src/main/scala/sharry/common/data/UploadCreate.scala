package sharry.common.data

import sharry.common.duration._
import io.circe._, io.circe.generic.semiauto._

/** Used to create uploads */
case class UploadCreate(id: String, description: String, validity: String, maxdownloads: Int, password: String)

object UploadCreate {
  def parseValidity(s: String): Either[String, Duration] = {
    Duration.parse(s).toEither
  }

  implicit val _uploadMetaDec: Decoder[UploadCreate] = deriveDecoder[UploadCreate]
  implicit val _uploadMetaEnc: Encoder[UploadCreate] = deriveEncoder[UploadCreate]

}
