package sharry.restserver.routes.headers

import cats.effect.IO

import munit.*
import org.http4s.*
import org.typelevel.ci.CIString

class SharryPasswordTest extends FunSuite {

  private def withHeader(value: String): Request[IO] =
    Request[IO](headers = Headers(Header.Raw(CIString("Sharry-Password"), value)))

  private def withCookie(value: String): Request[IO] =
    Request[IO]().addCookie(SharryPassword.name, value)

  test("reads the password from the header") {
    assertEquals(SharryPassword(withHeader("hunter2")).map(_.pass), Some("hunter2"))
  }

  test("reads the password from the cookie") {
    assertEquals(SharryPassword(withCookie("hunter2")).map(_.pass), Some("hunter2"))
  }

  test("header takes precedence over the cookie") {
    val req = withHeader("fromHeader").addCookie(SharryPassword.name, "fromCookie")
    assertEquals(SharryPassword(req).map(_.pass), Some("fromHeader"))
  }

  test("percent-decodes the header value") {
    assertEquals(SharryPassword(withHeader("a%20b%26c")).map(_.pass), Some("a b&c"))
  }

  test("percent-decodes the cookie value") {
    assertEquals(SharryPassword(withCookie("a%20b%26c")).map(_.pass), Some("a b&c"))
  }

  test("is empty when neither header nor cookie is present") {
    assertEquals(SharryPassword(Request[IO]()), None)
  }

  test("encodeCookieValue round-trips through the cookie read path") {
    // chars a naive encoder would let break the cookie, plus non-ascii
    val passwords =
      List("hunter2", "a b&c", "p;a,s\"s\\word", "=> ;Path=/;", "muenchen €", "%41%42")
    passwords.foreach { pw =>
      val encoded = SharryPassword.encodeCookieValue(pw)
      val req = Request[IO]().addCookie(SharryPassword.name, encoded)
      assertEquals(SharryPassword(req).map(_.pass), Some(pw), s"failed for: $pw")
    }
  }

  test("encodeCookieValue produces a value with no cookie-unsafe characters") {
    val del = 0x7f.toChar
    val unsafe = Set(' ', ';', ',', '"', '\\', '\r', '\n', '\t', del)
    val encoded =
      SharryPassword.encodeCookieValue("x; Max-Age=999\r\nSet-Cookie: a=b")
    assert(encoded.forall(c => !unsafe.contains(c) && c >= ' '), encoded)
  }
}
