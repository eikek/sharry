package sharry.restserver.config

import cats.data.{Validated, ValidatedNec}
import cats.syntax.all._

import sharry.backend.config.{Config => BackendConfig}
import sharry.common._
import sharry.logging.LogConfig

import com.comcast.ip4s.{Host, Port}

case class Config(
    baseUrl: LenientUri,
    aliasMemberEnabled: Boolean,
    bind: Config.Bind,
    logging: LogConfig,
    webapp: Config.Webapp,
    backend: BackendConfig
) {

  def validate: ValidatedNec[String, Config] = {
    val threshold = Duration.seconds(30)
    val validSession =
      if (backend.auth.sessionValid >= (webapp.authRenewal + threshold))
        Validated.validNec(())
      else
        Validated.invalidNec(
          s"session-valid time (${backend.auth.sessionValid}) must be " +
            s"at least 30s greater than webapp.auth-renewal (${webapp.authRenewal})"
        )

    val validValidity =
      if (backend.share.maxValidity >= webapp.defaultValidity) Validated.validNec(())
      else
        Validated.invalidNec(
          s"Default validity (${webapp.defaultValidity}) is larger than maximum ${backend.share.maxValidity}!"
        )

    val valdidTheme =
      Config.validateTheme(webapp.initialTheme) match {
        case ""  => Validated.validNec(())
        case str => Validated.invalidNec(str)
      }

    val validBackend = backend.validate.map(c => copy(backend = c))
    (validSession, validValidity, valdidTheme, validBackend)
      .mapN((_, _, _, c) => c)
  }

  def validOrThrow: Config =
    validate match {
      case Validated.Valid(cfg) => cfg
      case Validated.Invalid(errs) =>
        sys.error(
          s"Configuration is not valid: ${errs.toNonEmptyList.toList.mkString(", ")}"
        )
    }
}

object Config {

  case class Bind(address: Host, port: Port)

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
      initialTheme: String,
      oauthAutoRedirect: Boolean,
      customHead: String
  )

  private def validateTheme(str: String): String =
    if (str.equalsIgnoreCase("light") || str.equalsIgnoreCase("dark")) ""
    else s"Invalid theme: $str (use either 'light' or 'dark')"
}
