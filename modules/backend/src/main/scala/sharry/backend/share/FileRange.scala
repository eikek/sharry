package sharry.backend.share

import fs2.Stream
import bitpeace.FileMeta
import sharry.store.records.RShareFile

case class FileRange[F[_]](
    shareFile: RShareFile,
    fileMeta: FileMeta,
    data: Stream[F, Byte]
)
