package sharry.backend.share

import fs2.Stream

case class File[F[_]](
    name: Option[String],
    advertisedMime: Option[String],
    length: Option[Long],
    data: Stream[F, Byte]
)
