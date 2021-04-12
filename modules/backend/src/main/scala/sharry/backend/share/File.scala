package sharry.backend.share

import fs2.Stream

import bitpeace.Mimetype

case class File[F[_]](
    name: Option[String],
    advertisedMime: Option[Mimetype],
    length: Option[Long],
    data: Stream[F, Byte]
)
