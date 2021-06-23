package sharry.restserver.routes.tus

import bitpeace.Mimetype
import org.http4s.Request
import org.typelevel.ci.CIString

object SharryFileType {

  def apply[F[_]](req: Request[F]): Option[Mimetype] =
    req.headers
      .get(CIString("sharry-file-type"))
      .map(_.head.value)
      .flatMap(s => Mimetype.parse(s).toOption)

}
