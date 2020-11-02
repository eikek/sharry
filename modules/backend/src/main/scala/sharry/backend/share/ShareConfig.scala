package sharry.backend.share

import sharry.common._
import sharry.store.DomainCheckConfig

case class ShareConfig(
    chunkSize: ByteSize,
    maxSize: ByteSize,
    maxValidity: Duration,
    databaseDomainChecks: Seq[DomainCheckConfig]
)
