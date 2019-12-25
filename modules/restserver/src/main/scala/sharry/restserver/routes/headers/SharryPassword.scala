package sharry.restserver.routes.headers

import org.http4s.Request
import sharry.common.LenientUri
import org.http4s.syntax.string._
import sharry.common.Password

object SharryPassword {

  def apply[F[_]](req: Request[F]): Option[Password] =
    req.headers
      .get("sharry-password".ci)
      .map(_.value)
      .map(LenientUri.percentDecode)
      .map(Password.apply)

}
