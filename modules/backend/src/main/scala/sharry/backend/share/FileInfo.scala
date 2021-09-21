package sharry.backend.share

import sharry.common.ByteSize

case class FileInfo(
    length: ByteSize,
    name: Option[String],
    mime: String
)
