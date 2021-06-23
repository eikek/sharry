package sharry.restserver.routes.tus

import sharry.common.ByteSize

import org.http4s.Header
import org.http4s.Request
import org.typelevel.ci.CIString

object TusMaxSize {

  def get[F[_]](req: Request[F]): Option[ByteSize] =
    SharryFileLength.sizeHeader(req, "upload-length")

  def apply(size: ByteSize): Header.Raw =
    Header.Raw(CIString("Tus-Max-Size"), size.bytes.toString())

}
