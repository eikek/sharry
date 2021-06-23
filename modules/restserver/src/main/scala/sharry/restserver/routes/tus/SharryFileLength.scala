package sharry.restserver.routes.tus

import sharry.common.ByteSize

import org.http4s._
import org.typelevel.ci.CIString

object SharryFileLength {

  def apply[F[_]](req: Request[F]): Option[ByteSize] =
    sizeHeader(req, "sharry-file-length").orElse(sizeHeader(req, "upload-length"))

  private[tus] def sizeHeader[F[_]](req: Request[F], name: String): Option[ByteSize] =
    req.headers.get(CIString(name)).flatMap(_.head.value.toLongOption).map(ByteSize.apply)
}
