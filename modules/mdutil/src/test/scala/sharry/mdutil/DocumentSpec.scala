package sharry.mdutil

import org.scalatest._

class DocumentSpec extends FlatSpec with Matchers {

  "renderMd" should "return initial md text" in {
    val md = "# title1\n\nA paragraph with [link](./text.txt)."
    Document.parse(md).renderMd.trim should be (md)
  }

  "renderHtml" should "return html" in {
    val md = "# title1\n\nA paragraph with [link](./text.txt)."
    Document.parse(md).renderHtml should be ("<h1>title1</h1>\n<p>A paragraph with <a href=\"./text.txt\">link</a>.</p>\n")
  }

  "mapLinks" should "rewrite markdown links" in {
    val test = """|# title1
                  |this is an inline [link](./local.txt).""".stripMargin

    val doc = Document.parse(test).mapLinks(_ => Link("http://google.com"))
    doc.renderMd should be (
      """|# title1
         |
         |this is an inline [link](http://google.com).
         |""".stripMargin
    )
  }

  it should "not change on identity" in {
    val test = """|# title 1
                  |
                  |- [git](http://git-scm.org)
                  |
                  |text
                  |""".stripMargin

    val doc = Document.parse(test).mapLinks(identity _)
    doc.renderMd should be (test)
  }

  it should "create a new document" in {
    val test = """|# title1
                  |
                  |this is an inline [link](./local.txt).
                  |""".stripMargin

    val doc1 = Document.parse(test)
    val doc2 = doc1.mapLinks(_ => Link("bla"))
    doc1.renderMd should be (test)
    doc2.renderMd should be (test.replace("./local.txt", "bla"))
  }

  it should "rewrite html links" in {
    val testMd = """# title1
      |
      |and some text with <a href="bla.text">bla</a><ul> aha </ul>
      |
      |and images &amp;
      |
      |  <img src="html.jpg">
      |
      |end.""".stripMargin
    val doc = Document.parse(testMd).mapLinks(l => Link("http://google.com"))
    // indentation is not preserved, which is ok
    doc.renderMd should be ( """# title1
      |
      |and some text with <a href="http://google.com">bla</a><ul> aha </ul>
      |
      |and images &amp;
      |
      |<img src="http://google.com">
      |
      |end.
      |""".stripMargin)
  }
}
