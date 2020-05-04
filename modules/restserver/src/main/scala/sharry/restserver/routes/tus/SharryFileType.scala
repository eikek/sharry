package sharry.restserver.routes.tus

import org.http4s.Request
import org.http4s.syntax.string._
import bitpeace.Mimetype

object SharryFileType {

  def apply[F[_]](req: Request[F]): Option[Mimetype] =
    req.headers
      .get("sharry-file-type".ci)
      .map(_.value)
      .flatMap(s => Mimetype.parse(s).toOption)

}
