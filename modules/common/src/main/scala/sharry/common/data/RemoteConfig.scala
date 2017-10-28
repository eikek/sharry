package sharry.common.data

import io.circe._, io.circe.generic.semiauto._

case class RemoteConfig(
  urls: Map[String, String]
    , appName: String
    , authEnabled: Boolean
    , cookieAge: Long
    , chunkSize: Long
    , simultaneousUploads: Int
    , maxFiles: Int
    , maxFileSize: Long
    , maxValidity: String
    , projectName: String
    , aliasHeaderName: String
    , mailEnabled: Boolean
    , highlightjsTheme: String
    , welcomeMessage: String
)

object RemoteConfig {
  implicit val _remoteConfigEnc: Encoder[RemoteConfig] = deriveEncoder[RemoteConfig]
  implicit val _remoteConfigDec: Decoder[RemoteConfig] = deriveDecoder[RemoteConfig]
}
