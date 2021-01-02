package sharry.restserver

import sharry.backend.{Config => BackendConfig}
import sharry.common._

case class Config(
    baseUrl: LenientUri,
    responseTimeout: Duration,
    bind: Config.Bind,
    webapp: Config.Webapp,
    backend: BackendConfig
) {

  def validate: List[String] = {
    val threshold = Duration.seconds(30)
    List(
      if (backend.auth.sessionValid >= (webapp.authRenewal + threshold)) ""
      else
        s"session-valid time (${backend.auth.sessionValid}) must be " +
          s"at least 30s greater than webapp.auth-renewal (${webapp.authRenewal})"
    ).filter(_.nonEmpty)
  }

  def validOrThrow: Config =
    validate match {
      case Nil => this
      case errs =>
        sys.error(s"Configuration is not valid: ${errs.mkString(", ")}")
    }
}

object Config {

  case class Bind(address: String, port: Int)

  case class Webapp(
      appName: String,
      appIcon: String,
      appLogo: String,
      appFooter: String,
      appFooterVisible: Boolean,
      chunkSize: ByteSize,
      retryDelays: Seq[Duration],
      welcomeMessage: String,
      defaultLanguage: String,
      authRenewal: Duration,
      initialPage: String
  )

}
