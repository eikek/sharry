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

  def read(ctx: Context, linkPrefix: String): Stream[Task, ByteVector] =
    readAll(16384).
      through(text.utf8Decode).
      fold1(_ + _).
      map(mustache.parse).
      map(_.left.map(err => new Exception(s"${err._2} at ${err._1.pos}"))).
      through(pipe.rethrow).
      map(mustache.render(_)(ctx)).
      map(replaceLinks(linkPrefix)).
      through(text.utf8Encode).
      rechunkN(16384, true).
      chunks.map(c => ByteVector.view(c.toArray))

  private val markdownLink = """\[.*?\]\((.*?)\)""".r

  private def replaceLinks(prefix: String)(content: String): String = {
    if (prefix == "") content
    else markdownLink.replaceSomeIn(content, { m =>
      if (toc.names contains m.group(1)) {
        val off = m.start(1) - m.start(0)
        Some(m.matched.substring(0, off) + prefix + m.group(1) + ")")
      } else None
    })
  }
}
