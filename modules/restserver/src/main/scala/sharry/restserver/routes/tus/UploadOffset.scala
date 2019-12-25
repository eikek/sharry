package sharry.restserver.routes.tus

import org.http4s.Request
import sharry.common.ByteSize
import org.http4s.Header

object UploadOffset {

  def get[F[_]](req: Request[F]): Option[ByteSize] =
    SharryFileLength.sizeHeader(req, "upload-offset")

  def apply(size: ByteSize): Header =
    Header("Upload-Offset", size.bytes.toString())

}
