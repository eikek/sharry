package sharry.backend.mail

import cats.effect._

import sharry.common._
import sharry.store._
import sharry.store.records.RAccount

import emil.MailAddress
import munit._

class QueriesTest extends FunSuite with StoreFixture {

  test("get email from account") {
    withStore { store =>
      val accountId = Ident.unsafe("acc1")
      val account = RAccount(
        accountId,
        CIIdent.unsafe("jdoe"),
        AccountSource.intern,
        AccountState.Active,
        Password("test"),
        Some("test@test.com"),
        admin = true,
        0,
        None,
        Timestamp.Epoch
      )

      for {
        _ <- store.transact(RAccount.insert(account, "warn"))
        e <- store.transact(Queries.getEmail(accountId))
        _ <- IO(assertEquals(e, Some(MailAddress(Some("jdoe"), "test@test.com"))))
      } yield ()
    }
  }
}
