package sharry.backend.auth
import sharry.common.*

import scodec.bits.ByteVector

case class AuthConfig(
    serverSecret: ByteVector,
    sessionValid: Duration,
    fixed: AuthConfig.Fixed,
    http: AuthConfig.Http,
    httpBasic: AuthConfig.HttpBasic,
    command: AuthConfig.Command,
    proxy: AuthConfig.Proxy,
    internal: AuthConfig.Internal,
    oauth: Seq[AuthConfig.OAuth]
) {

  def isOAuthOnly: Boolean =
    fixed.disabled && http.disabled &&
      httpBasic.disabled && command.disabled &&
      internal.disabled && proxy.disabled && oauth.exists(_.enabled)

  def isProxyAuthOnly: Boolean =
    fixed.disabled && http.disabled &&
      httpBasic.disabled && command.disabled &&
      internal.disabled && !oauth.exists(_.enabled) && proxy.enabled

  def isAutoLogin: Boolean =
    fixed.disabled && http.disabled &&
      httpBasic.disabled && command.disabled &&
      internal.disabled && (oauth.exists(_.enabled) || proxy.enabled)
}

object AuthConfig {

  final case class Proxy(
      enabled: Boolean,
      userHeader: String,
      emailHeader: Option[String]
  ) {
    def disabled = !enabled
  }

  case class Fixed(enabled: Boolean, user: Ident, password: Password, order: Int) {
    def disabled = !enabled
  }

  case class Http(
      enabled: Boolean,
      url: LenientUri,
      method: String,
      body: String,
      contentType: String,
      order: Int
  ) {
    def disabled = !enabled
  }

  case class HttpBasic(enabled: Boolean, url: LenientUri, method: String, order: Int) {
    def disabled: Boolean = !enabled
  }

  case class Command(
      enabled: Boolean,
      program: Seq[String],
      success: Int,
      order: Int
  ) {
    def disabled = !enabled
  }

  case class Internal(enabled: Boolean, order: Int) {
    def disabled = !enabled
  }

  case class OAuth(
      id: Ident,
      enabled: Boolean,
      name: String,
      authorizeUrl: LenientUri,
      tokenUrl: LenientUri,
      userUrl: LenientUri,
      userIdKey: String,
      userEmailKey: Option[String],
      scope: String,
      clientId: String,
      clientSecret: String,
      icon: Option[String]
  )

  object OAuth {

    def github(clientId: String, clientSecret: String): OAuth =
      OAuth(
        Ident.unsafe("github"),
        enabled = true,
        "Github",
        LenientUri.unsafe("https://github.com/login/oauth/authorize"),
        LenientUri.unsafe("https://github.com/login/oauth/access_token"),
        LenientUri.unsafe("https://api.github.com/user"),
        "login",
        None,
        "",
        clientId,
        clientSecret,
        Some("github")
      )
  }

}
