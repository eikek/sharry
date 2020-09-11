package sharry.backend.mail

import minitest._
import cats.effect._
import scala.concurrent.ExecutionContext
import emil.MailAddress
import sharry.common._
import sharry.store.records.RAccount
import sharry.store._

object QueriesTest extends SimpleTestSuite with StoreFixture {
  implicit val CS          = IO.contextShift(ExecutionContext.global)

  test("get email from account") {
    withStore { store =>
      val accountId = Ident.unsafe("acc1")
      val account = RAccount(
        accountId,
        Ident.unsafe("jdoe"),
        AccountSource.intern,
        AccountState.Active,
        Password("test"),
        Some("test@test.com"),
        true,
        0,
        None,
        Timestamp.Epoch
      )

      for {
        _ <- store.transact(RAccount.insert(account))
        e <- store.transact(Queries.getEmail(accountId))
        _ <- IO(assertEquals(e, Some(MailAddress(Some("jdoe"), "test@test.com"))))
      } yield ()
    }
  }
}
