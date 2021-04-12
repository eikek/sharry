package sharry.backend.share

import sharry.common._

import bitpeace.Mimetype

case class FileData(
    id: Ident,
    shareId: Ident,
    metaId: Ident,
    name: Option[String],
    mimetype: Mimetype,
    length: ByteSize,
    checksum: String,
    chunks: Int,
    chunksize: ByteSize,
    created: Timestamp,
    saved: ByteSize
)
