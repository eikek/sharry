package sharry.restserver.routes.tus

import org.http4s.Request
import org.typelevel.ci.CIString

object SharryFileType {

  def apply[F[_]](req: Request[F]): Option[String] =
    req.headers
      .get(CIString("sharry-file-type"))
      .map(_.head.value)
}
