package sharry.restserver.routes.headers

import sharry.common.LenientUri
import sharry.common.Password

import org.http4s.Request
import org.http4s.syntax.string._

object SharryPassword {

  def apply[F[_]](req: Request[F]): Option[Password] =
    req.headers
      .get("sharry-password".ci)
      .map(_.value)
      .flatMap(LenientUri.percentDecode)
      .map(Password.apply)

}
