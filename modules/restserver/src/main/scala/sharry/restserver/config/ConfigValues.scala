package sharry.restserver.config

import cats.syntax.all._
import ciris._
import org.http4s.Uri
import sharry.restserver.config.Hocon.HoconAt
import com.comcast.ip4s.{Host, Port}
import sharry.common._
import sharry.logging.Level
import sharry.logging.LogConfig
import sharry.store.JdbcConfig
import scodec.bits.ByteVector
import sharry.backend.auth.AuthConfig
import scala.jdk.CollectionConverters._
import cats.Applicative

object ConfigValues extends ConfigDecoders:
  private val hocon = Hocon.at("sharry.restserver")
  private def senv(envName: String) = env(s"SHARRY_${envName}")
  private def key(hoconPath: String, envName: String) =
    hocon(hoconPath).as[String].or(senv(envName))

  private def keyMap[A, B](hoconPath: String, envName: String)(using ConfigDecoder[String, A], ConfigDecoder[String, B]) =
    hocon(hoconPath).as[Map[A, B]]

  private def keyList[A](hoconPath: String, envName: String)(using ConfigDecoder[String, A]) =
    hocon(hoconPath).as[List[A]]

  val baseUrl = key("base-url", "BASE_URL").as[Uri]

  val bind = {
    val address = key("bind.address", "BIND_ADDRESS").as[Host]
    val port = key("bind.port", "BIND_PORT").as[Port]
    (address, port).mapN(Config.Bind.apply)
  }

  val fileDownload = {
    val chunkSize = key("file-download.download-chunk-size",
      "FILE_DOWNLOAD_CHUNK_SIZE").as[ByteSize]
    chunkSize.map(Config.FileDownload.apply)
  }

  val logConfig = {
    val minLevel = key("logging.minimum-level", "LOGGING_MINIMUM_LEVEL").as[Level]
    val fmt = key("logging.format", "LOGGING_FORMAT").as[LogConfig.Format]
    val extraLevel = keyMap[String, Level]("logging.levels", "LOGGING_LEVELS")
    (minLevel, fmt, extraLevel).mapN(LogConfig.apply)
  }

  val aliasMemberEnabled = key("alias-member-enabled", "ALIAS_MEMBER_ENABLED").as[Boolean]

  val webapp = {
    val name = key("webapp.app-name", "WEBAPP_NAME")
    val icon = key("webapp.app-icon", "WEBAPP_ICON")
    val iconDark = key("webapp.app-icon-dark", "WEBAPP_ICON_DARK")
    val logo = key("webapp.app-logo", "WEBAPP_LOGO")
    val logoDark = key("webapp.app-logo-dark", "WEBAPP_LOGO_DARK")
    val footer = key("webapp.app-footer", "WEBAPP_FOOTER")
    val footerVisible = key("webapp.app-footer-visible", "WEBAPP_FOOTER_VISIBLE").as[Boolean]
    val chunkSize = key("webapp.chunk-size", "WEBAPP_CHUNK_SIZE").as[ByteSize]
    val retryDelays= keyList[Duration]("webapp.retry-delays", "WEBAPP_RETRY_DELAYS")
    val welcomeMsg = key("webapp.welcome-message", "WEBAPP_WELCOME_MESSAGE")
    val defaultLang = key("webapp.default-language", "WEBAPP_DEFAULT_LANGUAGE")
    val authRenewal = key("webapp.auth-renewal", "WEBAPP_AUTH_RENEWAL").as[Duration]
    val initialPage = key("webapp.initial-page", "WEBAPP_INITIAL_PAGE")
    val defaultValidity = key("webapp.default-validity", "WEBAPP_DEFAULT_VALIDITY").as[Duration]
    val initialTheme = key("webapp.initial-theme", "WEBAPP_INITIAL_THEME")
    val oauthRedirect = key("webapp.oauth-auto-redirect", "WEBAPP_OAUTH_AUTO_REDIRECT").as[Boolean]
    val customHead = key("webapp.custom-head", "WEBAPP_CUSTOM_HEAD")
    (name, icon, iconDark, logo, logoDark, footer, footerVisible, chunkSize, retryDelays, welcomeMsg, defaultLang, authRenewal, initialPage, defaultValidity, initialTheme, oauthRedirect, customHead).mapN(Config.Webapp.apply)
  }


  val authFixed: ConfigValue[Effect, AuthConfig.Fixed] = {
    def k(p: String, e: String) =
      key(s"backend.auth.fixed.$p", s"BACKEND_AUTH_FIXED_$e")

    val enabled = k("enabled", "ENABLED").as[Boolean]
    val user = k("user", "USER").as[Ident]
    val pass = k("password", "PASSWORD").as[Password].redacted
    val order = k("order", "ORDER").as[Int]
    (enabled, user, pass, order).mapN(AuthConfig.Fixed.apply)
  }

  val authHttp = {
    def k(p: String, e: String) =
      key(s"backend.auth.http.$p", s"BACKEND_AUTH_HTTP_$e")

    val enabled = k("enabled", "ENABLED").as[Boolean]
    val url = k("url", "URL").as[LenientUri]
    val method = k("method", "METHOD")
    val body = k("body", "BODY")
    val contentType = k("content-type", "CONTENT_TYPE")
    val order = k("order", "ORDER").as[Int]
    (enabled, url, method, body, contentType, order).mapN(AuthConfig.Http.apply)
  }

  val authHttpBasic = {
    def k(p: String, e: String) =
      key(s"backend.auth.http-basic.$p", s"BACKEND_AUTH_HTTP_BASIC_$e")

    val enabled = k("enabled", "ENABLED").as[Boolean]
    val url = k("url", "URL").as[LenientUri]
    val method = k("method", "METHOD")
    val order = k("order", "ORDER").as[Int]
    (enabled, url, method, order).mapN(AuthConfig.HttpBasic.apply)
  }

  val authCommand = {
    def k(p: String, e: String) =
      key(s"backend.auth.command.$p", s"BACKEND_AUTH_COMMAND_$e")

    val enabled = k("enabled", "ENABLED").as[Boolean]
    val program = keyList[String]("backend.auth.command.program", "BACKEND_AUTH_COMMAND_PROGRAM")
    val success = k("success", "SUCCESS").as[Int]
    val order = k("order", "ORDER").as[Int]
    (enabled, program, success, order).mapN(AuthConfig.Command.apply)
  }

  val authInternal = {
    def k(p: String, e: String) =
      key(s"backend.auth.internal.$p", s"BACKEND_AUTH_INTERNAL_$e")

    val enabled = k("enabled", "ENABLED").as[Boolean]
    val order = k("order", "ORDER").as[Int]
    (enabled, order).mapN(AuthConfig.Internal.apply)
  }

  val authProxy = {
    def k(p: String, e: String) =
      key(s"backend.auth.proxy.$p", s"BACKEND_AUTH_INTERNAL_$e")

    val enabled = k("enabled", "ENABLED").as[Boolean]
    val userHeader = k("user-header", "USER_HEADER")
    val emailHeader = k("email-header", "EMAIL_HEADER").option
    (enabled, userHeader, emailHeader).mapN(AuthConfig.Proxy.apply)
  }

  def authOAuth(id: Ident) = {
    def k(p: String, e: String) =
      key(s"backend.auth.oauth.${id.id}.$p", s"BACKEND_AUTH_OAUTH_${id.id.toUpperCase()}_$e")
    val idkey = ConfigKey(s"oauth id key: ${id.id}")
    val enabled = k("enabled", "ENABLED").as[Boolean]
    val name = k("name", "NAME")
    val icon = k("icon", "ICON").option
    val scope = k("scope", "SCOPE")
    val authorizeUrl = k("authorize-url", "AUTHORIZE_URL").as[LenientUri]
    val tokenUrl = k("token-url", "TOKEN_URL").as[LenientUri]
    val userUrl = k("user-url", "USER_URL").as[LenientUri]
    val userIdkey = k("user-id-key", "USER_ID_KEY")
    val userEmailKey = k("user-email-key", "USER_EMAIL_KEY").option
    val clientId = k("client-id", "CLIENT_ID")
    val clientSecret = k("client-secret", "CLIENT_SECRET")
    (ConfigValue.loaded(idkey, id), enabled, name, authorizeUrl, tokenUrl, userUrl, userIdkey, userEmailKey, scope, clientId, clientSecret, icon).mapN(AuthConfig.OAuth.apply)
  }

  val authOAuthKeys = {
    def stringsToIds(strs: List[String]) =
      strs.traverse(Ident.fromString) match
          case Right(ids) => ConfigValue.loaded(ConfigKey(""), ids)
          case Left(err) => ConfigValue.failed(ConfigError(err))

    val hoconKeys =
      hocon("backend.auth.oauth")
        .map(_.atKey("a").getConfig("a").root.keySet.asScala.toList)
        .flatMap(stringsToIds)

    val envKeys =
      senv("BACKEND_AUTH_OAUTH_IDS").map(s => s.split(',').toList.map(_.trim))
      .flatMap(stringsToIds)

    hoconKeys.or(envKeys)
  }

  val authOAuthSeq =
    authOAuthKeys.flatMap(ids =>
      ids.foldLeft(ConfigValue.loaded(ConfigKey(""), List.empty[AuthConfig.OAuth])) {
       (cv, id) => cv.flatMap(l => authOAuth(id).map(_ :: l))
    })

  val auth = {
    def k(p: String, e: String) =
      key(s"backend.auth.$p", s"BACKEND_AUTH_$e")
    val serverSecret = k("server-secret", "SERVER_SECRET").as[ByteVector]
    val sessionValid = k("session-valid", "SESSION_VALID").as[Duration]
    (serverSecret, sessionValid, authFixed, authHttp, authHttpBasic, authCommand, authProxy, authInternal, authOAuthSeq).mapN(AuthConfig.apply)
  }

  val jdbc = {
    val url = key("backend.jdbc.url", "BACKEND_JDBC_URL").as[LenientUri]
    val user = key("backend.jdbc.user", "BACKEND_JDBC_USER")
    val pass = key("backend.jdbc.password", "BACKEND_JDBC_PASSWORD").redacted
    (url, user, pass).mapN(JdbcConfig.apply)
  }


end ConfigValues
