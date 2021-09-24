package sharry.backend.share

import fs2.Stream

import sharry.store.records.{RFileMeta, RShareFile}

case class FileRange[F[_]](
    shareFile: RShareFile,
    fileMeta: RFileMeta,
    data: Stream[F, Byte]
)
