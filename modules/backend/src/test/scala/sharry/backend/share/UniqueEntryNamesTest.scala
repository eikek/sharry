package sharry.backend.share

import munit.FunSuite

/** Regression test for zip downloads failing silently when a share contains files with
  * the same name (`ZipOutputStream` rejects duplicate entries).
  */
class UniqueEntryNamesTest extends FunSuite {

  private def names(in: String*): List[String] =
    OShare.uniqueEntryNames(in.toList)(identity).map(_._2)

  test("distinct names are unchanged") {
    assertEquals(names("a.txt", "b.txt"), List("a.txt", "b.txt"))
  }

  test("duplicates get a numeric suffix before the extension") {
    assertEquals(
      names("a.txt", "a.txt", "a.txt"),
      List("a.txt", "a (2).txt", "a (3).txt")
    )
  }

  test("duplicates without extension") {
    assertEquals(names("Scan", "Scan"), List("Scan", "Scan (2)"))
  }

  test("dotfile is not split at the leading dot") {
    assertEquals(names(".env", ".env"), List(".env", ".env (2)"))
  }

  test("generated name does not collide with an existing one") {
    assertEquals(
      names("a.txt", "a (2).txt", "a.txt"),
      List("a.txt", "a (2).txt", "a (3).txt")
    )
  }

  test("generated name does not collide with a later original name") {
    assertEquals(
      names("a.txt", "a.txt", "a (2).txt"),
      List("a.txt", "a (2).txt", "a (2) (2).txt")
    )
  }

  test("items are kept paired with their names, in order") {
    val r = OShare.uniqueEntryNames(List(1 -> "x", 2 -> "x"))(_._2)
    assertEquals(r, List((1 -> "x", "x"), (2 -> "x", "x (2)")))
  }
}
