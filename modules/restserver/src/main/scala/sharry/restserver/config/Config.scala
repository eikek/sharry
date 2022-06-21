package sharry.restserver.config

import sharry.backend.config.{Config => BackendConfig}
import sharry.common._
import sharry.logging.LogConfig

case class Config(
    baseUrl: LenientUri,
    responseTimeout: Duration,
    aliasMemberEnabled: Boolean,
    bind: Config.Bind,
    logging: LogConfig,
    webapp: Config.Webapp,
    backend: BackendConfig
) {

  def validate: List[String] = {
    val threshold = Duration.seconds(30)
    List(
      if (backend.auth.sessionValid >= (webapp.authRenewal + threshold)) ""
      else
        s"session-valid time (${backend.auth.sessionValid}) must be " +
          s"at least 30s greater than webapp.auth-renewal (${webapp.authRenewal})",
      if (backend.share.maxValidity >= webapp.defaultValidity) ""
      else
        s"Default validity (${webapp.defaultValidity}) is larger than maximum ${backend.share.maxValidity}!",
      Config.validateTheme(webapp.initialTheme)
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
      appIconDark: String,
      appLogo: String,
      appLogoDark: String,
      appFooter: String,
      appFooterVisible: Boolean,
      chunkSize: ByteSize,
      retryDelays: Seq[Duration],
      welcomeMessage: String,
      defaultLanguage: String,
      authRenewal: Duration,
      initialPage: String,
      defaultValidity: Duration,
      initialTheme: String
  )

  private def validateTheme(str: String): String =
    if (str.equalsIgnoreCase("light") || str.equalsIgnoreCase("dark")) ""
    else s"Invalid theme: $str (use either 'light' or 'dark')"
}
