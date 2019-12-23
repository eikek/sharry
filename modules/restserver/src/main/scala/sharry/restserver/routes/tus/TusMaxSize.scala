package sharry.restserver.routes.tus

import org.http4s.Request
import sharry.common.ByteSize
import org.http4s.Header

object TusMaxSize {

  def get[F[_]](req: Request[F]): Option[ByteSize] =
    SharryFileLength.sizeHeader(req, "upload-length")

  def apply(size: ByteSize): Header =
    Header("Tus-Max-Size", size.bytes.toString())

}
