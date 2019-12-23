package sharry.restserver

import org.http4s._
import org.http4s.util._
import sharry.backend.auth._
import sharry.common.AccountId

case class CookieData(auth: AuthToken) {
  def accountId: AccountId = auth.account
  def asString: String     = auth.asString

  def asCookie(cfg: Config): ResponseCookie = {
    val domain = cfg.baseUrl.host
    val sec    = cfg.baseUrl.scheme.exists(_.endsWith("s"))
    val path   = cfg.baseUrl.path / "api" / "v2"
    ResponseCookie(
      CookieData.cookieName,
      asString,
      domain = domain,
      path = Some(path.asString),
      httpOnly = true,
      secure = sec
    )
  }
}
object CookieData {
  val cookieName = "sharry_auth"
  val headerName = "Sharry-Auth"

  def authenticator[F[_]](r: Request[F]): Either[String, String] =
    fromCookie(r).orElse(fromHeader(r))

  def fromCookie[F[_]](req: Request[F]): Either[String, String] =
    for {
      header <- headers.Cookie.from(req.headers).toRight("Cookie parsing error")
      cookie <- header.values.toList
                 .find(_.name == cookieName)
                 .toRight("Couldn't find the authcookie")
    } yield cookie.content

  def fromHeader[F[_]](req: Request[F]): Either[String, String] =
    req.headers
      .get(CaseInsensitiveString(headerName))
      .map(_.value)
      .toRight("Couldn't find an authenticator")

  def deleteCookie(cfg: Config): ResponseCookie =
    ResponseCookie(
      cookieName,
      "",
      domain = cfg.baseUrl.host,
      path = Some(cfg.baseUrl.path / "api" / "v2").map(_.asString),
      httpOnly = true,
      secure = cfg.baseUrl.scheme.exists(_.endsWith("s")),
      maxAge = Some(-1)
    )
}
