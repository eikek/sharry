package sharry.backend.share

import fs2.Stream

import sharry.common._

case class ShareData[F[_]](
    validity: Duration,
    maxViews: Int,
    description: Option[String],
    password: Option[Password],
    name: Option[String],
    files: Stream[F, File[F]]
)

object ShareData {}
