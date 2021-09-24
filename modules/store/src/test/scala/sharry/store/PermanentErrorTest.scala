package sharry.store

import munit._

class PermanentErrorTest extends FunSuite {
  val nativePart = "value for domain safe_bytea violates check constraint"
  val errorMsg =
    """value for domain safe_bytea violates check constraint "safe_bytea_check""""

  test("find substring in error message") {
    val checks = Seq(DomainCheckConfig(true, nativePart, "Oh no, a virus!"))
    PermanentError.create(checks).unapply(new Exception(errorMsg)) match {
      case Some(m) => assertEquals(m, checks.head.message)
      case None    => fail("Check was not recognized")
    }
  }

  test("don't find when disabled") {
    val errorMsg =
      """value for domain safe_bytea violates check constraint "safe_bytea_check""""
    val checks = Seq(DomainCheckConfig(false, nativePart, "Oh no, a virus!"))
    PermanentError.create(checks).unapply(new Exception(errorMsg)) match {
      case Some(_) => fail("Check was not disabled!")
      case None    => //ok
    }
  }

  test("don't find when donmain not included in error message") {
    val errorMsg = """value blabla violates unique constraint"""
    val checks = Seq(DomainCheckConfig(false, nativePart, "Oh no, a virus!"))
    PermanentError.create(checks).unapply(new Exception(errorMsg)) match {
      case Some(_) => fail("Unexpected check found!")
      case None    => //ok
    }
  }
}
