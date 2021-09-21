package sharry.backend.share

import sharry.common._

case class FileData(
    id: Ident,
    shareId: Ident,
    metaId: Ident,
    name: Option[String],
    mimetype: String,
    length: ByteSize,
    checksum: String,
    created: Timestamp,
    saved: ByteSize
)
