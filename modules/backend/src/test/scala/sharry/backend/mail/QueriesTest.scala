package sharry.backend.mail

import minitest._
import sharry.store._
import cats.effect._
import sharry.common._
import scala.concurrent.ExecutionContext
import _root_.doobie.util.transactor.Transactor
import sharry.store.doobie.StoreImpl
import sharry.store.records.RAccount
import scala.util.Random
import scodec.bits.ByteVector
import java.nio.file.Paths
import emil.MailAddress
import org.log4s.getLogger

object QueriesTest extends SimpleTestSuite {
  private[this] val logger = getLogger
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

  def withStore(code: Store[IO] => IO[Unit]): Unit = {
    def transactor(blocker: Blocker, jdbc: JdbcConfig): Transactor[IO] =
      Transactor.fromDriverManager[IO](
        jdbc.driverClass,
        jdbc.url.asString,
        jdbc.user,
        jdbc.password,
        blocker
      )

    val dbname = IO {
      val bytes = new Array[Byte](16)
      Random.nextBytes(bytes)
      val name = ByteVector.view(bytes).toBase64NoPad
      val db   = Paths.get("./target", name).normalize.toAbsolutePath
      logger.debug(s"Using db: $db")
      db.toString
    }

    val store = for {
      blocker <- Blocker[IO]
      db      <- Resource.liftF(dbname)
      jdbc = JdbcConfig(
        LenientUri.unsafe(s"jdbc:h2:$db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE"),
        "sa",
        ""
      )
      tx = transactor(blocker, jdbc)
      st = new StoreImpl[IO](jdbc, tx)
      _ <- Resource.liftF(st.migrate)
    } yield st

    store.use(code).unsafeRunSync()
  }
}
