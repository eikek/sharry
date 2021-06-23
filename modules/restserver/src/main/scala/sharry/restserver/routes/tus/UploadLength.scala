package sharry.restserver.routes.tus

import sharry.common.ByteSize

import org.http4s.Header
import org.http4s.Request
import org.typelevel.ci.CIString

object UploadLength {

  def get[F[_]](req: Request[F]): Option[ByteSize] =
    SharryFileLength.sizeHeader(req, "upload-length")

  def apply(size: ByteSize): Header.Raw =
    Header.Raw(CIString("Upload-Length"), size.bytes.toString())

}
