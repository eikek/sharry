package sharry.restserver.routes.tus

import org.http4s._
import org.http4s.syntax.string._
import sharry.common.ByteSize

object SharryFileLength {

  def apply[F[_]](req: Request[F]): Option[ByteSize] =
    sizeHeader(req, "sharry-file-length").orElse(sizeHeader(req, "upload-length"))

  private[tus] def sizeHeader[F[_]](req: Request[F], name: String): Option[ByteSize] =
    req.headers.get(name.ci).flatMap(_.value.toLongOption).map(ByteSize.apply)
}
