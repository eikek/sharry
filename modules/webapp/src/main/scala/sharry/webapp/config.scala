package sharry.webapp

object config {

  case class RemoteConfig(
    urls: Map[String, String]
      , appName: String
      , authEnabled: Boolean
      , cookieAge: Long
      , chunkSize: Long
      , simultaneousUploads: Int
      , maxFiles: Int
      , maxFileSize: Long
      , projectName: String
      , aliasHeaderName: String
  )

}
