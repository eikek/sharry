package sharry.restserver.routes

import cats.effect._

import sharry.restapi.model._
import sharry.restserver.{BuildInfo, Config}

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object InfoRoutes {

  def apply[F[_]: Sync](cfg: Config): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._
    HttpRoutes.of[F] {
      case GET -> Root / "version" =>
        Ok(
          VersionInfo(
            BuildInfo.version,
            BuildInfo.builtAtMillis,
            BuildInfo.builtAtString,
            BuildInfo.gitHeadCommit.getOrElse(""),
            BuildInfo.gitDescribedVersion.getOrElse("")
          )
        )
      case GET -> Root / "appconfig" =>
        Ok(appConfig(cfg))
    }
  }

  private def getBaseUrl(cfg: Config): String =
    if (cfg.baseUrl.isLocal) cfg.baseUrl.path.asString
    else cfg.baseUrl.asString

  def appConfig(cfg: Config): AppConfig = {
    val assetPath = s"/app/assets/sharry-webapp/${BuildInfo.version}"
    val logoUrl =
      if (cfg.webapp.appLogo.nonEmpty) cfg.webapp.appLogo
      else s"$assetPath/img/logo.png"
    val logoUrlDark =
      if (cfg.webapp.appLogoDark.nonEmpty) cfg.webapp.appLogoDark
      else s"$assetPath/img/logo-dark.png"
    val iconUrl =
      if (cfg.webapp.appIcon.nonEmpty) cfg.webapp.appIcon
      else s"$assetPath/img/icon.svg"
    val iconUrlDark =
      if (cfg.webapp.appIconDark.nonEmpty) cfg.webapp.appIconDark
      else s"$assetPath/img/icon-dark.svg"
    AppConfig(
      cfg.webapp.appName,
      getBaseUrl(cfg),
      logoUrl,
      logoUrlDark,
      iconUrl,
      iconUrlDark,
      cfg.webapp.appFooter,
      cfg.webapp.appFooterVisible,
      cfg.backend.signup.mode,
      cfg.backend.auth.oauth
        .filter(_.enabled)
        .map(oa => OAuthItem(oa.id, oa.name, oa.icon))
        .toList,
      cfg.webapp.chunkSize.bytes,
      cfg.webapp.retryDelays.map(_.millis).toList,
      cfg.backend.share.maxValidity,
      cfg.backend.share.maxSize,
      cfg.backend.mail.enabled,
      cfg.webapp.welcomeMessage,
      cfg.webapp.defaultLanguage,
      cfg.webapp.authRenewal,
      cfg.webapp.initialPage,
      cfg.backend.auth.isOAuthOnly,
      cfg.aliasMemberEnabled
    )
  }

}
