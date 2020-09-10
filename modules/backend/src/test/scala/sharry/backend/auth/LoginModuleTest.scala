package sharry.backend.auth

import minitest._
import cats.effect._
import cats.implicits._
import scodec.bits.ByteVector
import sharry.common._
import cats.data.Kleisli

object LoginModuleTest extends SimpleTestSuite {

  val cfg = AuthConfig(
    ByteVector.fromValidHex("caffee"),
    Duration.hours(1),
    AuthConfig.Fixed(true, Ident.unsafe("admin"), Password("admin"), 1),
    AuthConfig.Http(true, LenientUri.unsafe("http://test.com"), "GET", "", "", 2),
    AuthConfig.HttpBasic(true, LenientUri.unsafe("http://test.com"), "GET", 3),
    AuthConfig.Command(true, Seq.empty, 0, 4),
    AuthConfig.Internal(true, 5),
    Seq.empty
  )

  val accId = Ident.unsafe("x123id")
  val ops   = AddAccount.AccountOps(Kleisli(_ => IO(accId)), Kleisli(_ => IO(())))

  def commandModule(success: Boolean): LoginModule[IO] = {
    val runner = CommandAuth.RunCommand[IO]((up, cfg) => IO(success))
    new CommandAuth[IO](cfg, ops, runner).login
  }

  def httpModule(success: Boolean): LoginModule[IO] = {
    val runner = HttpAuth.RunRequest[IO]((up, cfg) => IO(success))
    new HttpAuth[IO](cfg, ops, runner).login
  }

  def httpBasicModule(success: Boolean): LoginModule[IO] = {
    val runner = HttpBasicAuth.RunRequest[IO]((up, cfg) => IO(success))
    new HttpBasicAuth[IO](cfg, ops, runner).login
  }

  def checkNewAccount(result: Option[LoginResult]): Unit =
    result match {
      case Some(LoginResult.Ok(t)) =>
        assertEquals(t.account.id, accId)
        assertEquals(t.account.userLogin, Ident.unsafe("jdoe"))
        assertEquals(t.account.admin, false)
        assertEquals(t.account.alias, None)
      case e =>
        fail(s"unexpected result: $e")
    }

  def checkInvalidAuth(result: Option[LoginResult]): Unit =
    result match {
      case Some(LoginResult.InvalidAuth) =>
      // ok
      case e =>
        fail(s"unexpected result: $e")
    }

  test("module create account on success") {
    val modules = List(httpModule(true), commandModule(true), httpBasicModule(true))
    val data    = UserPassData("jdoe", Password("test"))

    modules.traverse(_.apply(data).map(checkNewAccount)).map(_.combineAll).unsafeRunSync()
  }

  test("module invalid result on failure") {
    val modules = List(httpModule(false), commandModule(false), httpBasicModule(false))
    val data    = UserPassData("jdoe", Password("test"))

    modules
      .traverse(_.apply(data).map(checkInvalidAuth))
      .map(_.combineAll)
      .unsafeRunSync()

  }

}
