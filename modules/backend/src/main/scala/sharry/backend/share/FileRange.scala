package sharry.backend.share

import fs2.Stream

import sharry.store.records.RShareFile

import bitpeace.FileMeta

case class FileRange[F[_]](
    shareFile: RShareFile,
    fileMeta: FileMeta,
    data: Stream[F, Byte]
)
