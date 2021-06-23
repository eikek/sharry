package sharry.restserver.routes.headers

import sharry.common.LenientUri
import sharry.common.Password

import org.http4s.Request
import org.typelevel.ci.CIString

object SharryPassword {

  def apply[F[_]](req: Request[F]): Option[Password] =
    req.headers
      .get(CIString("sharry-password"))
      .map(_.head.value)
      .flatMap(LenientUri.percentDecode)
      .map(Password.apply)

}
