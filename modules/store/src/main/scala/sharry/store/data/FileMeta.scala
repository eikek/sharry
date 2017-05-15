package sharry.store.data

import java.time._
import java.util.UUID
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

  def randomId: String = UUID.randomUUID().toString

}
