package sharry.backend.auth

import cats.data.Kleisli
import cats.effect._
import cats.effect.unsafe.implicits.global
import cats.implicits._

import sharry.backend.account.OAccount
import sharry.backend.auth.AddAccount.AccountOps
import sharry.common._
import sharry.store.Store
import sharry.store.StoreFixture
import sharry.store.doobie.Sql
import sharry.store.records.RAccount

import _root_.doobie._
import munit._
import scodec.bits.ByteVector

class LoginModuleTest extends FunSuite {

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

  def noOps(admin: Boolean, login: Ident) =
    AccountOps(
      Kleisli(_ =>
        IO(
          RAccount(
            accId,
            CIIdent(login),
            AccountSource.Extern,
            AccountState.Active,
            Password("test"),
            None,
            admin,
            0,
            None,
            Timestamp.Epoch
          )
        )
      ),
      Kleisli(_ => IO(()))
    )
  def storeOps(store: Store[IO]): Resource[IO, AccountOps[IO]] =
    OAccount[IO](store).map(AccountOps.from[IO])

  def commandModule(success: Boolean, ops: AccountOps[IO]): LoginModule[IO] = {
    val runner = CommandAuth.RunCommand[IO]((_, _) => IO(success))
    new CommandAuth[IO](cfg, ops, runner).login
  }

  def httpModule(success: Boolean, ops: AccountOps[IO]): LoginModule[IO] = {
    val runner = HttpAuth.RunRequest[IO]((_, _) => IO(success))
    new HttpAuth[IO](cfg, ops, runner).login
  }

  def httpBasicModule(success: Boolean, ops: AccountOps[IO]): LoginModule[IO] = {
    val runner = HttpBasicAuth.RunRequest[IO]((_, _) => IO(success))
    new HttpBasicAuth[IO](cfg, ops, runner).login
  }

  def checkNewAccount(result: Option[LoginResult]): Unit =
    result match {
      case Some(LoginResult.Ok(t)) =>
        assertEquals(t.account.userLogin, Ident.unsafe("jdoe"))
        assertEquals(t.account.admin, false)
        assertEquals(t.account.alias, None)
      case e =>
        fail(s"unexpected result: $e")
    }

  def checkAdminAccount(result: Option[LoginResult]): Unit =
    result match {
      case Some(LoginResult.Ok(t)) =>
        assertEquals(t.account.userLogin, Ident.unsafe("jdoe"))
        assertEquals(t.account.admin, true)
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
    val modules = List(
      httpModule(true, noOps(false, Ident.unsafe("jdoe"))),
      commandModule(true, noOps(false, Ident.unsafe("jdoe"))),
      httpBasicModule(true, noOps(false, Ident.unsafe("jdoe")))
    )
    val data = UserPassData("jdoe", Password("test"))

    modules.traverse(_.apply(data).map(checkNewAccount)).map(_.combineAll).unsafeRunSync()
  }

  test("module invalid result on failure") {
    val modules = List(
      httpModule(false, noOps(false, Ident.unsafe("jdoe"))),
      commandModule(false, noOps(false, Ident.unsafe("jdoe"))),
      httpBasicModule(false, noOps(false, Ident.unsafe("jdoe")))
    )
    val data = UserPassData("jdoe", Password("test"))

    modules
      .traverse(_.apply(data).map(checkInvalidAuth))
      .map(_.combineAll)
      .unsafeRunSync()
  }

  test("external module loads existing account from db") {
    def updateAdmin(flag: Boolean): ConnectionIO[Int] =
      Sql
        .updateRow(RAccount.table, Fragment.empty, RAccount.Columns.admin.setTo(flag))
        .update
        .run

    val ops =
      for {
        store <- StoreFixture.makeStore[IO]
        ops   <- storeOps(store)
      } yield (ops, store)

    val data = UserPassData("jdoe", Password("test"))

    ops
      .use { case (op, store) =>
        val modules = List(
          httpModule(true, op),
          commandModule(true, op),
          httpBasicModule(true, op)
        )
        for {
          _   <- modules.traverse(_.apply(data).map(checkNewAccount)).map(_.combineAll)
          as1 <- store.transact(RAccount.findAll("")).compile.toVector
          _ = as1.foreach(a => assertEquals(a.admin, false))
          _   <- store.transact(updateAdmin(true))
          as2 <- store.transact(RAccount.findAll("")).compile.toVector
          _ = as2.foreach(a => assertEquals(a.admin, true))
          _ <- modules.traverse(_.apply(data).map(checkAdminAccount)).map(_.combineAll)
        } yield ()
      }
      .unsafeRunSync()
  }
}
