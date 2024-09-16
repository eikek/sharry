package sharry.restserver.config

import scala.jdk.CollectionConverters.*

import cats.syntax.all.*
import fs2.io.file.Path

import sharry.backend.auth.AuthConfig
import sharry.backend.config.{Config as BackendConfig, CopyFilesConfig, FilesConfig}
import sharry.backend.job.CleanupConfig
import sharry.backend.mail.MailConfig
import sharry.backend.share.ShareConfig
import sharry.backend.signup.SignupConfig
import sharry.common.*
import sharry.logging.Level
import sharry.logging.LogConfig
import sharry.store.ComputeChecksumConfig
import sharry.store.DomainCheckConfig
import sharry.store.FileStoreConfig
import sharry.store.FileStoreType
import sharry.store.JdbcConfig

import ciris.*
import com.comcast.ip4s.{Host, Port}
import emil.MailAddress
import emil.SSLType
import scodec.bits.ByteVector
import yamusca.data.Template

object ConfigValues extends ConfigDecoders:
  private val hocon = Hocon.at("sharry.restserver")
  private def senv(envName: String) = env(s"SHARRY_${envName}")
  private def key(hoconPath: String, envName: String) =
    senv(envName).or(hocon(hoconPath).as[String])

  private def keyMap[A, B](hoconPath: String, envName: String)(using
      ConfigDecoder[String, A],
      ConfigDecoder[String, B]
  ) = {
    val envMap = senv(s"${envName}_NAMES")
      .as[List[String]]
      .listflatMap { k =>
        val value = senv(s"${envName}_$k").as[B]
        val ckey = ConfigKey(s"${envName} key: $k")
        val kk = ConfigDecoder[String, A]
          .decode(Some(ckey), k)
          .fold(ConfigValue.failed, ConfigValue.loaded(ckey, _))

        value.flatMap(v => kk.map(_ -> v))
      }
      .map(_.toMap)

    envMap.or(hocon(hoconPath).as[Map[A, B]])
  }

  private def keyList[A](hoconPath: String, envName: String)(using
      ConfigDecoder[String, A]
  ) =
    senv(envName).as[List[A]].or(hocon(hoconPath).as[List[A]])

  private def mapKeys[A](hoconPath: String, envName: String)(using
      ConfigDecoder[String, A]
  ) = {
    val hoconKeys =
      hocon(hoconPath)
        .map(_.atKey("a").getConfig("a").root.keySet.asScala.toList)
        .as[List[A]]
    val envKeys = senv(envName).as[List[A]]
    envKeys.or(hoconKeys)
  }

  val baseUrl = key("base-url", "BASE_URL").as[LenientUri]

  val maxPageSize = key("max-page-size", "MAX_PAGE_SIZE").as[Int].flatMap { n =>
    if (n <= 0)
      ConfigValue.failed(ConfigError(s"max-page-size must be greater than 0, got $n"))
    else ConfigValue.loaded(ConfigKey("max-page-size"), n)
  }

  val bind = {
    val address = key("bind.address", "BIND_ADDRESS").as[Host]
    val port = key("bind.port", "BIND_PORT").as[Port]
    (address, port).mapN(Config.Bind.apply)
  }

  val fileDownload = {
    val chunkSize =
      key("file-download.download-chunk-size", "FILE_DOWNLOAD_CHUNK_SIZE").as[ByteSize]
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
    val footerVisible =
      key("webapp.app-footer-visible", "WEBAPP_FOOTER_VISIBLE").as[Boolean]
    val chunkSize = key("webapp.chunk-size", "WEBAPP_CHUNK_SIZE").as[ByteSize]
    val retryDelays = keyList[Duration]("webapp.retry-delays", "WEBAPP_RETRY_DELAYS")
    val welcomeMsg = key("webapp.welcome-message", "WEBAPP_WELCOME_MESSAGE")
    val defaultLang = key("webapp.default-language", "WEBAPP_DEFAULT_LANGUAGE")
    val authRenewal = key("webapp.auth-renewal", "WEBAPP_AUTH_RENEWAL").as[Duration]
    val initialPage = key("webapp.initial-page", "WEBAPP_INITIAL_PAGE")
    val defaultValidity =
      key("webapp.default-validity", "WEBAPP_DEFAULT_VALIDITY").as[Duration]
    val initialTheme = key("webapp.initial-theme", "WEBAPP_INITIAL_THEME")
    val oauthRedirect =
      key("webapp.oauth-auto-redirect", "WEBAPP_OAUTH_AUTO_REDIRECT").as[Boolean]
    val customHead = key("webapp.custom-head", "WEBAPP_CUSTOM_HEAD")
    (
      name,
      icon,
      iconDark,
      logo,
      logoDark,
      footer,
      footerVisible,
      chunkSize,
      retryDelays,
      welcomeMsg,
      defaultLang,
      authRenewal,
      initialPage,
      defaultValidity,
      initialTheme,
      oauthRedirect,
      customHead
    ).mapN(Config.Webapp.apply)
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
    val program =
      keyList[String]("backend.auth.command.program", "BACKEND_AUTH_COMMAND_PROGRAM")
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
      key(
        s"backend.auth.oauth.${id.id}.$p",
        s"BACKEND_AUTH_OAUTH_${id.id.toUpperCase()}_$e"
      )
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
    (
      ConfigValue.loaded(idkey, id),
      enabled,
      name,
      authorizeUrl,
      tokenUrl,
      userUrl,
      userIdkey,
      userEmailKey,
      scope,
      clientId,
      clientSecret,
      icon
    ).mapN(AuthConfig.OAuth.apply)
  }

  val authOAuthSeq =
    mapKeys[Ident]("backend.auth.oauth", "BACKEND_AUTH_OAUTH_IDS").listflatMap(authOAuth)

  val auth = {
    def k(p: String, e: String) =
      key(s"backend.auth.$p", s"BACKEND_AUTH_$e")
    val serverSecret = k("server-secret", "SERVER_SECRET").as[ByteVector]
    val sessionValid = k("session-valid", "SESSION_VALID").as[Duration]
    (
      serverSecret,
      sessionValid,
      authFixed,
      authHttp,
      authHttpBasic,
      authCommand,
      authProxy,
      authInternal,
      authOAuthSeq
    ).mapN(AuthConfig.apply)
  }

  val jdbc = {
    val url = key("backend.jdbc.url", "BACKEND_JDBC_URL").as[LenientUri]
    val user = key("backend.jdbc.user", "BACKEND_JDBC_USER")
    val pass = key("backend.jdbc.password", "BACKEND_JDBC_PASSWORD").redacted
    (url, user, pass).mapN(JdbcConfig.apply)
  }

  def fileStoreConfig(id: String) = {
    def k(p: String, e: String) =
      key(s"backend.files.stores.$id.$p", s"BACKEND_FILES_STORES_${id.toUpperCase}_$e")

    val enabled = k("enabled", "ENABLED").as[Boolean]
    k("type", "TYPE").as[FileStoreType].flatMap {
      case FileStoreType.DefaultDatabase =>
        enabled.map(FileStoreConfig.DefaultDatabase.apply)

      case FileStoreType.FileSystem =>
        val dir = k("directory", "DIRECTORY").as[Path]
        val cleanDirs = k("clean-empty-dirs", "CLEAN_EMPTY_DIRS").as[Boolean]
        (enabled, dir, cleanDirs).mapN(FileStoreConfig.FileSystem.apply)

      case FileStoreType.S3 =>
        val endpoint = k("endpoint", "ENDPOINT")
        val accessKey = k("access-key", "ACCESS_KEY")
        val secretKey = k("secret-key", "SECRET_KEY")
        val bucket = k("bucket", "BUCKET")
        (enabled, endpoint, accessKey, secretKey, bucket).mapN(FileStoreConfig.S3.apply)
    }
  }

  val copyFiles = {
    def k(p: String, e: String) =
      key(s"backend.files.copy-files.$p", s"BACKEND_FILES_COPY_FILES_$e")

    val enabled = k("enable", "ENABLE").as[Boolean]
    val source = k("source", "SOURCE").as[Ident]
    val target = k("target", "TARGET").as[Ident]
    val parallel = k("parallel", "PARALLEL").as[Int]
    (enabled, source, target, parallel).mapN(CopyFilesConfig.apply)
  }

  val files = {
    val defaultStore =
      key("backend.files.default-store", "BACKEND_FILES_DEFAULT_STORE").as[Ident]
    val stores = mapKeys[Ident]("backend.files.stores", "BACKEND_FILES_STORES_IDS")
      .listflatMap(id => fileStoreConfig(id.id).map(id -> _))
      .map(_.toMap)
    (defaultStore, stores, copyFiles).mapN(FilesConfig.apply)
  }

  val computeChecksum = {
    def k(p: String, e: String) =
      key(s"backend.compute-checksum.$p", s"BACKEND_COMPUTE_CHECKSUM_$e")

    val enable = k("enable", "ENABLE").as[Boolean]
    val capacity = k("capacity", "CAPACITY").as[Int]
    val parallel = k("parallel", "PARALLEL").as[Int]
    val useDefault = k("use-default", "USE_DEFAULT").as[Boolean]
    (enable, capacity, parallel, useDefault).mapN(ComputeChecksumConfig.apply)
  }

  val signup = {
    def k(p: String, e: String) =
      key(s"backend.signup.$p", s"BACKEND_SIGNUP_$e")

    val mode = k("mode", "MODE").as[SignupMode]
    val inviteTime = k("invite-time", "INVITE_TIME").as[Duration]
    val invitePass = k("invite-password", "INVITE_PASSWORD").as[Password]
    (mode, inviteTime, invitePass).mapN(SignupConfig.apply)
  }

  def domainCheck(id: String) = {
    def k(p: String, e: String) =
      key(
        s"backend.share.database-domain-checks.$id.$p",
        s"BACKEND_SHARE_DATABASE_DOMAIN_CHECKS_${id.toUpperCase}.$e"
      )

    val enabled = k("enabled", "ENABLED").as[Boolean]
    val nativeM = k("native", "NATIVE")
    val message = k("message", "MESSAGE")
    (enabled, nativeM, message).mapN(DomainCheckConfig.apply)
  }

  val share = {
    def k(p: String, e: String) =
      key(s"backend.share.$p", s"BACKEND_SHARE_$e")

    val chunkSize = k("chunk-size", "CHUNK_SIZE").as[ByteSize]
    val maxSize = k("max-size", "MAX_SIZE").as[ByteSize]
    val maxValid = k("max-validity", "MAX_VALIDITY").as[Duration]
    val domainChecks = mapKeys[String](
      "backend.share.database-domain-checks",
      "BACKEND_SHARE_DATABASE_DOMAIN_CHECKS_IDS"
    )
      .listflatMap(domainCheck)
    (chunkSize, maxSize, maxValid, domainChecks).mapN(ShareConfig.apply)
  }

  val cleanup = {
    def k(p: String, e: String) =
      key(s"backend.cleanup.$p", s"BACKEND_CLEANUP_$e")

    val enabled = k("enabled", "ENABLED").as[Boolean]
    val interval = k("interval", "INTERVAL").as[Duration]
    val invalidAge = k("invalid-age", "INVALID_AGE").as[Duration]
    (enabled, interval, invalidAge).mapN(CleanupConfig.apply)
  }

  val mailSmtp = {
    def k(p: String, e: String) =
      key(s"backend.mail.smtp.$p", s"BACKEND_MAIL_SMTP_$e")

    val host = k("host", "HOST")
    val port = k("port", "PORT").as[Int]
    val user = k("user", "USER")
    val pass = k("password", "PASSWORD").as[Password].redacted
    val sslType = k("ssl-type", "SSL_TYPE").as[SSLType]
    val checkCerts =
      k("check-certificates", "CHECK_CERTIFICATES").as[Boolean].default(true)
    val timeout = k("timeout", "TIMEOUT").as[Duration]
    val defaultFrom = k("default-from", "DEFAULT_FROM").as[Option[MailAddress]]
    val listId = k("list-id", "LIST_ID")
    (host, port, user, pass, sslType, checkCerts, timeout, defaultFrom, listId).mapN(
      MailConfig.Smtp.apply
    )
  }

  def mailTemplate(id: String) = {
    def k(p: String, e: String) =
      key(
        s"backend.mail.templates.$id.$p",
        s"BACKEND_MAIL_TEMPLATES_${id.toUpperCase}_$e"
      )

    val subject = k("subject", "SUBJECT").as[Template]
    val body = k("body", "BODY").as[Template]
    (subject, body).mapN(MailConfig.MailTpl.apply)
  }

  val mail = {
    def k(p: String, e: String) =
      key(s"backend.mail.$p", s"BACKEND_MAIL_$e")

    val enabled = k("enabled", "ENABLED").as[Boolean]
    val downloadTpl = mailTemplate("download")
    val aliasTpl = mailTemplate("alias")
    val uploadTpl = mailTemplate("upload-notify")
    val templates = (downloadTpl, aliasTpl, uploadTpl).mapN(MailConfig.Templates.apply)
    (enabled, mailSmtp, templates).mapN(MailConfig.apply)
  }

  val backendConfig =
    (jdbc, signup, auth, share, cleanup, mail, files, computeChecksum).mapN(
      BackendConfig.apply
    )

  val fullConfig =
    (
      baseUrl,
      aliasMemberEnabled,
      maxPageSize,
      bind,
      fileDownload,
      logConfig,
      webapp,
      backendConfig
    )
      .mapN(
        Config.apply
      )

end ConfigValues
