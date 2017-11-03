package sharry.common.data

import java.time.Instant
import io.circe._, io.circe.generic.semiauto._
import sharry.common.JsonCodec
import sharry.common.duration._

/** Used when retrieving an upload from the server */
// TODO rename
case class UploadWeb(
  id: String
    , login: String
    , alias: Option[String]
    , aliasName: Option[String]
    , validity: Duration
    , maxDownloads: Int
    , requiresPassword: Boolean
    , validated: List[String]
    , description: Option[String] = None
    , created: Instant = Instant.now
    , downloads: Int = 0
    , lastDownload: Option[Instant] = None
    , publishId: Option[String] = None
    , publishDate: Option[Instant] = None
    , validUntil: Option[Instant] = None
)

object UploadWeb {
  import JsonCodec._

  implicit val _uploadWebDec: Decoder[UploadWeb] = deriveDecoder[UploadWeb]
  implicit val _uploadWebEnc: Encoder[UploadWeb] = deriveEncoder[UploadWeb]

}
