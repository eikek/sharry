package sharry.mdutil

import com.vladsch.flexmark.ast._
import com.vladsch.flexmark.ast.{Document => MDocument, Link => MLink}
import com.vladsch.flexmark.util.sequence._
import org.jsoup.nodes.{Document => JsoupDocument}
import scala.collection.JavaConverters._

private[mdutil] class LinkProcessor(f: Link => Link) { self =>

  private val visitor = new NodeVisitor(
    visitHandler[Image](self.process),
    visitHandler[MLink](self.process),
    visitHandler[Reference](self.process),
    visitHandler[HtmlBlock](self.processHtmlBlock),
    visitHandler[HtmlInline](self.processHtmlInline)
  )

  def processDocument(doc: MDocument): Unit =
    visitor.visit(doc)

  // note, this is copied from this example:
  // https://github.com/vsch/flexmark-java/blob/7b140d97c04e359ec8dfa4c2160241b810596437/flexmark-java-samples/src/com/vladsch/flexmark/samples/FormatterWithMods.java
  private def process(n: LinkNodeBase): Unit = {
    val org = Link(n.getPageRef.normalizeEOL)
    val next = f(org)
    if (next != org) {
      n.setUrlChars(PrefixedSubSequence.of(next.path, n.getPageRef.subSequence(0,0)))
      n.setChars(SegmentedSequence.of(n.getSegmentsForChars().toList.asJava, n.getChars))
    }
  }

  private def processHtmlInline(html: HtmlInline): Unit = {
    val doc = org.jsoup.Jsoup.parse(html.getChars.normalizeEOL)
    val changed = changeAttr(doc, "src") | changeAttr(doc, "href")
    if (changed) {
      val tag = doc.body.child(0)
      val cnt = tag.outerHtml()
      // must cut off the closing tag inserted by jsoup
      html.setChars(chars(cnt.dropRight(tag.nodeName.length + 3)))
    }
  }

  private def processHtmlBlock(html: HtmlBlock): Unit = {
    val doc = org.jsoup.Jsoup.parse(html.getSpanningChars.normalizeEOL)
    val changed = changeAttr(doc, "src") | changeAttr(doc, "href")
    if (changed) {
      html.setChars(chars(doc.body.html + "\n"))
    }
  }

  private def changeAttr(html: JsoupDocument, attr: String): Boolean = {
    html.select(s"[$attr]").asScala.
      foldLeft(false) { (flag, el) =>
        val org = Link(el.attr(attr))
        val next = f(org)
        if (next != org) {
          el.attr(attr, next.path)
          true
        } else flag
      }
  }
}

private[mdutil] object LinkProcessor {

  def apply(f: Link => Link): LinkProcessor =
    new LinkProcessor(f)

}
