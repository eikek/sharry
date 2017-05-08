package sharry.store.data

import scodec.bits.ByteVector
import sharry.store.data.sizes._

case class FileChunk(
  fileId: String,
  chunkNr: Int,
  chunkData: ByteVector) {

  lazy val chunkLength: Size = Bytes(chunkData.size)

}
