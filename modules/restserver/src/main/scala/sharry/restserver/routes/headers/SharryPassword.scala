package sharry.restserver.routes.headers

import java.nio.charset.StandardCharsets

import sharry.common.LenientUri
import sharry.common.Password

import org.http4s.Request
import org.typelevel.ci.CIString

object SharryPassword {

  val name: String = "sharry-password"

  private val headerName = CIString(name)

  private val unreserved: Set[Char] =
    (('A' to 'Z') ++ ('a' to 'z') ++ ('0' to '9')).toSet ++ Set('-', '_', '.', '~')

  // Encode into unreserved chars only so the value is safe in a cookie.
  // LenientUri.percentEncode is for URI paths and leaves ';', '"', '\' and
  // control chars alone, which would break the Set-Cookie header.
  def encodeCookieValue(value: String): String = {
    val out = new StringBuilder
    value.getBytes(StandardCharsets.UTF_8).foreach { b =>
      val c = (b & 0xff).toChar
      if (unreserved.contains(c)) out.append(c)
      else out.append("%%%02X".format(b & 0xff))
    }
    out.toString
  }

  // Header for the webapp's XHR calls, cookie for plain browser downloads
  // that can't set a header.
  def apply[F[_]](req: Request[F]): Option[Password] =
    fromHeader(req).orElse(fromCookie(req))

  private def fromHeader[F[_]](req: Request[F]): Option[Password] =
    req.headers
      .get(headerName)
      .map(_.head.value)
      .flatMap(LenientUri.percentDecode)
      .map(Password.apply)

  private def fromCookie[F[_]](req: Request[F]): Option[Password] =
    req.cookies
      .find(_.name == name)
      .map(_.content)
      .flatMap(LenientUri.percentDecode)
      .map(Password.apply)

}
