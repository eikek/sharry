package sharry.backend.share
import bitpeace.Mimetype

case class FileInfo(
    length: Long,
    name: Option[String],
    mime: Mimetype
)
