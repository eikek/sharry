package sharry.backend.share

import cats.effect.*
import fs2.Stream

import sharry.common.*
import sharry.store.*
import sharry.store.records.{RAccount, RAlias}

import munit.FunSuite

/** With `requireSharePassword` enabled, alias uploads must still work. The password is
  * then enforced when the share is published.
  */
class OShareRequirePasswordTest extends FunSuite with StoreFixture {

  private val cfg = ShareConfig(
    chunkSize = ByteSize(64L * 1024),
    maxSize = ByteSize(100L * 1024 * 1024),
    maxValidity = Duration.days(1),
    databaseDomainChecks = Nil,
    zipMaxSize = ByteSize(100L * 1024 * 1024),
    requireSharePassword = true
  )

  private def shareData(password: Option[Password]): ShareData[IO] =
    ShareData(
      Duration.days(1),
      10,
      None,
      password,
      None,
      Stream.empty
    )

  private def setup(store: Store[IO]): IO[(RAccount, RAlias)] =
    for {
      now <- Timestamp.current[IO]
      accountId <- Ident.randomId[IO]
      account = RAccount(
        accountId,
        CIIdent.unsafe("jdoe"),
        AccountSource.intern,
        AccountState.Active,
        Password("test"),
        None,
        admin = true,
        0,
        None,
        now
      )
      _ <- store.transact(RAccount.insert(account, "warn"))
      aliasId <- Ident.randomId[IO]
      alias = RAlias(aliasId, accountId, "upload", Duration.days(1), true, now)
      _ <- store.transact(RAlias.insert(alias))
    } yield (account, alias)

  test("alias upload without password succeeds") {
    withStore { store =>
      OShare[IO](store, cfg).use { oshare =>
        for {
          (account, alias) <- setup(store)
          res <- oshare.create(shareData(None), account.accountId(Some(alias.id)))
          _ <- IO(assert(res.toOption.isDefined, s"Expected success, got: $res"))
        } yield ()
      }
    }
  }

  test("user upload without password is rejected") {
    withStore { store =>
      OShare[IO](store, cfg).use { oshare =>
        for {
          (account, _) <- setup(store)
          res <- oshare.create(shareData(None), account.accountId(None))
          _ <- IO(assert(res.toOption.isEmpty, s"Expected failure, got: $res"))
        } yield ()
      }
    }
  }

  test("publishing requires a password") {
    withStore { store =>
      OShare[IO](store, cfg).use { oshare =>
        for {
          (account, alias) <- setup(store)
          created <- oshare.create(shareData(None), account.accountId(Some(alias.id)))
          shareId = created.toOption.getOrElse(fail(s"Could not create share: $created"))
          accId = account.accountId(None)

          first <- oshare.publish(shareId, accId, reuseId = false).value.attempt
          _ <- IO(assert(first.isLeft, s"Expected publish to fail, got: $first"))

          _ <- oshare.setPassword(accId, shareId, Some(Password("secret"))).value
          second <- oshare.publish(shareId, accId, reuseId = false).value.attempt
          _ <- IO(assertEquals(second, Right(Some(()))))
        } yield ()
      }
    }
  }
}
