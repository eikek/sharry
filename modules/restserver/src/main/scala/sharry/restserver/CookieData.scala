package sharry.restserver

import sharry.backend.auth.*
import sharry.common.*

import org.http4s.*
import org.typelevel.ci.CIString

case class CookieData(auth: AuthToken) {
  def accountId: AccountId = auth.account
  def asString: String = auth.asString

  def asCookie(baseUrl: LenientUri): ResponseCookie = {
    val sec = baseUrl.scheme.exists(_.endsWith("s"))
    val path = baseUrl.path / "api" / "v2"
    ResponseCookie(
      CookieData.cookieName,
      asString,
      domain = None,
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
      header <- req.headers.get[headers.Cookie].toRight("Cookie parsing error")
      cookie <-
        header.values.toList
          .find(_.name == cookieName)
          .toRight("Couldn't find the authcookie")
    } yield cookie.content

  def fromHeader[F[_]](req: Request[F]): Either[String, String] =
    req.headers
      .get(CIString(headerName))
      .map(_.head.value)
      .toRight("Couldn't find an authenticator")

  def deleteCookie(baseUrl: LenientUri): ResponseCookie =
    ResponseCookie(
      cookieName,
      "",
      domain = None,
      path = Some(baseUrl.path / "api" / "v2").map(_.asString),
      httpOnly = true,
      secure = baseUrl.scheme.exists(_.endsWith("s")),
      maxAge = Some(-1)
    )
}
