package sharry.common.data

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
