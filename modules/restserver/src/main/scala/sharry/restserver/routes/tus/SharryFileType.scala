package sharry.restserver.routes.tus

import bitpeace.Mimetype
import org.http4s.Request
import org.http4s.syntax.string._

object SharryFileType {

  def apply[F[_]](req: Request[F]): Option[Mimetype] =
    req.headers
      .get("sharry-file-type".ci)
      .map(_.value)
      .flatMap(s => Mimetype.parse(s).toOption)

}
