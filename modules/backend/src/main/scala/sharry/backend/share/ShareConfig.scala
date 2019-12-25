package sharry.backend.share

import sharry.common._

case class ShareConfig(chunkSize: ByteSize, maxSize: ByteSize, maxValidity: Duration)
