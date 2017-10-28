package sharry.store.data

import java.time._
import java.util.UUID
import io.circe._, io.circe.generic.semiauto._
import sharry.common.JsonCodec
import sharry.common.mime._
import sharry.common.sizes._

case class FileMeta(
  id: String,
  timestamp: Instant,
  mimetype: MimeType,
  length: Size,
  chunks: Int,
  chunksize: Size
) {

  def incLength(n: Size) = copy(length = length + n)
  def incChunks(n: Int) = copy(chunks = chunks + n)
  def setMimeType(mt: MimeType) = copy(mimetype = mt.orElse(mimetype))
}

object FileMeta {
  import JsonCodec._

  def randomId: String = UUID.randomUUID().toString

  implicit val _fileMetaDec: Decoder[FileMeta] = deriveDecoder[FileMeta]
  implicit val _fileMetaEnc: Encoder[FileMeta] = deriveEncoder[FileMeta]
}
