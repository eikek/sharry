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

  def read(ctx: Context, pathPrefix: String, linkPrefix: String): Stream[Task, ByteVector] = {
    if (name.endsWith(".md")) {
      readAll(16384).
        through(text.utf8Decode).
        fold1(_ + _).
        map(mustache.parse).
        map(_.left.map(err => new Exception(s"${err._2} at ${err._1.pos}"))).
        through(pipe.rethrow).
        map(mustache.render(_)(ctx)).
        map(replaceLinks(pathPrefix, linkPrefix)).
        through(text.utf8Encode).
        rechunkN(16384, true).
        chunks.map(c => ByteVector.view(c.toArray))
    } else {
      readAll(16384).
        chunks.map(c => ByteVector.view(c.toArray))
    }
  }

  private val markdownLink = """\[.*?\]\((.*?)\)""".r
  private val htmlSrcLink = """src="(.*?)"""".r

  private def replaceLinks(pathPrefix: String, mdLinkPrefix: String)(content: String): String = {
    if (mdLinkPrefix == "") content
    else List(markdownLink, htmlSrcLink).foldLeft(content) { (r, link) =>
      link.replaceSomeIn(r, { m =>
        val file = m.group(1)
        val pre = if (file.endsWith(".md")) mdLinkPrefix else pathPrefix
        if (toc.names.contains(file)) {
          val starting = m.start(1) - m.start(0)
          val end1 = m.end(1) - m.start(0)
          val end2 = m.end(0) - m.start(0)
          Some(m.matched.substring(0, starting) + pre + m.group(1) + m.matched.substring(end1, end2))
        } else None
      })
    }
  }
}
