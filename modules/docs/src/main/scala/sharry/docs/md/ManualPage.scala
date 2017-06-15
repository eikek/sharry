package sharry.docs.md

import java.net.URL
import fs2.{io, text, pipe, Stream, Task}
import scodec.bits.ByteVector
import yamusca.imports._

case class ManualPage(
  name: String
    , checksum: String
    , mimetype: String
    , size: Long
    , url: URL) {


  def readAll(chunkSize: Int): Stream[Task, Byte] =
    io.readInputStream(Task.delay(url.openStream), chunkSize)

  def read(ctx: Context): Stream[Task, ByteVector] =
    readAll(8192).
      through(text.utf8Decode).
      fold1(_ + _).
      map(mustache.parse).
      map(_.left.map(err => new Exception(s"${err.message} at ${err.index}"))).
      through(pipe.rethrow).
      map(mustache.render(_)(ctx)).
      through(text.utf8Encode).
      chunks.map(c => ByteVector.view(c.toArray))

}
