package sharry.restserver.routes.tus

import sharry.common.ByteSize

import org.http4s.Header
import org.http4s.Request

object UploadOffset {

  def get[F[_]](req: Request[F]): Option[ByteSize] =
    SharryFileLength.sizeHeader(req, "upload-offset")

  def apply(size: ByteSize): Header =
    Header("Upload-Offset", size.bytes.toString())

}
