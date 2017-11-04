package sharry.store.account

import org.scalatest._
import doobie.imports._
import fs2.interop.cats._
import sharry.store._
import sharry.common.data._

class SqlAccountStoreTest extends FlatSpec with Matchers with StoreFixtures {

  "create" should "create a new account" in newDb { xa =>
    val store = SqlAccountStore(xa)
    val acc = Account("test", Some("pass"))
    store.accountExists(acc.login).runLast.unsafeRun.get should be (false)
    store.createAccount(acc).run.unsafeRun
    store.accountExists(acc.login).runLast.unsafeRun.get should be (true)
  }

  it should "save all data of the account" in newDb { xa =>
    val store = SqlAccountStore(xa)
    val acc = Account.newInternal("test", "pass")
    store.createAccount(acc).run.unsafeRun
    store.getAccount(acc.login).runLast.unsafeRun.get should be (acc)
  }

  "delete" should "remove an account" in newDb { xa =>
    val store = SqlAccountStore(xa)
    val acc = Account("test", Some("pass"))
    store.createAccount(acc).run.unsafeRun

    store.accountExists(acc.login).runLast.unsafeRun.get should be (true)
    store.deleteAccount(acc.login).runLast.unsafeRun.get should be (true)
    store.accountExists(acc.login).runLast.unsafeRun.get should be (false)

    sql"""select count(*) from Upload""".query[Int].unique.transact(xa).unsafeRun should be (0)
  }


  "set enabled" should "set enabled flag" in newDb { xa =>
    val store = SqlAccountStore(xa)
    val acc = Account("test", Some("pass"), enabled = true)
    store.createAccount(acc).run.unsafeRun

    store.setAccountEnabled(acc.login, false).runLast.unsafeRun.get should be (true)
    val accdb = store.getAccount(acc.login).runLast.unsafeRun.get
    accdb should be (acc.copy(enabled = false))
  }
}
