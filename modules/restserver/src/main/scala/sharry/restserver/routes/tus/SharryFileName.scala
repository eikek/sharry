package sharry.restserver.routes.tus

import org.http4s.Request
import sharry.common.LenientUri
import org.http4s.syntax.string._

object SharryFileName {

  def apply[F[_]](req: Request[F]): Option[String] =
    req.headers.get("sharry-file-name".ci).map(_.value).flatMap(LenientUri.percentDecode)

}
