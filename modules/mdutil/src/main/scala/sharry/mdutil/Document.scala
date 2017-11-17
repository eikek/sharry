package sharry.mdutil

import com.vladsch.flexmark.ast.{Document => MDocument}
import com.vladsch.flexmark.html.HtmlRenderer;
import com.vladsch.flexmark.parser.Parser;
import com.vladsch.flexmark.util.options.MutableDataSet
import com.vladsch.flexmark.formatter.internal.Formatter
import com.vladsch.flexmark.ext.gfm.strikethrough.StrikethroughExtension
import com.vladsch.flexmark.ext.gfm.tables.TablesExtension

import scala.collection.JavaConverters._

/** A markdown document. Only exposing the little features needed in sharry. */
trait Document {

  def renderHtml: String

  def renderMd: String

  def mapLinks(f: Link => Link): Document
}

object Document {

  def parse(md: String): Document =
    new DocumentImpl(parser.parse(md))


  private[mdutil] val formatter = {
    val opts = new MutableDataSet()
    Formatter.builder(opts).build
  }

  private[mdutil] val parser = {
    val opts = new MutableDataSet()
    opts.set(Parser.EXTENSIONS, List(StrikethroughExtension.create, TablesExtension.create).asJava)
    Parser.builder(opts).build
  }

  private[mdutil] val htmlRenderer = {
    val opts = new MutableDataSet()
    HtmlRenderer.builder(opts).build
  }

  private class DocumentImpl(delegate: MDocument) extends Document {
    def copy: MDocument = parser.parse(delegate.getChars)

    def renderHtml: String =
      htmlRenderer.render(delegate)

    def renderMd: String =
      Document.formatter.render(delegate)

    def mapLinks(f: Link => Link): Document = {
      val d = copy
      LinkProcessor(f).processDocument(d)
      new DocumentImpl(d)
    }
  }
}
