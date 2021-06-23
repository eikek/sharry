package sharry.restserver.routes.tus

import sharry.common.LenientUri

import org.http4s.Request
import org.typelevel.ci.CIString

object SharryFileName {

  def apply[F[_]](req: Request[F]): Option[String] =
    req.headers
      .get(CIString("sharry-file-name"))
      .map(_.head.value)
      .flatMap(LenientUri.percentDecode)

}
