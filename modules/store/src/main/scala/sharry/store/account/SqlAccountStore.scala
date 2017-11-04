package sharry.store.account

import fs2.{Task, Stream}
import doobie.imports._
import fs2.interop.cats._
import sharry.common.data.Account
import sharry.store.Limit

class SqlAccountStore(xa: Transactor[Task]) extends AccountStore with SqlStatements {

  def accountExists(login: String): Stream[Task,Boolean] = Stream.eval {
    existsAccount(login).transact(xa)
  }

  def getAccount(login: String): Stream[Task,Account] =
    Stream.eval(selectAccount(login).transact(xa)).flatMap {
      case Some(a) => Stream(a)
      case None => Stream.empty
    }

  def createAccount(account: Account): Stream[Task,Unit] = {
    Stream.eval(insertAccount(account).run.transact(xa)).map(_ => ())
  }

  def updateAccount(account: Account): Stream[Task,Boolean] = Stream.eval {
    updateAccountSql(account).run.map(_ > 0).transact(xa)
  }

  def updatePassword(login: String, password: Option[String]): Stream[Task,Boolean] =
    Stream.eval(sqlUpdatePassword(login, password).run.map(_ > 0).transact(xa))

  def updateEmail(login: String, email: Option[String]): Stream[Task,Boolean] =
    Stream.eval(sqlUpdateEmail(login, email).run.map(_ > 0).transact(xa))

  def setAccountEnabled(login: String, flag: Boolean): Stream[Task,Boolean] = Stream.eval {
    updateEnabledSql(login, flag).run.map(_ > 0).transact(xa)
  }

  def deleteAccount(login: String): Stream[Task,Boolean] = Stream.eval {
    val t = for {
      n <- deleteAccountSql(login).run
    } yield n > 0
    t.transact(xa)
  }

  def listLogins(q: String, limit: Option[Limit]): Stream[Task,String] =
    selectLogins(q, limit).process.transact(xa)

}

object SqlAccountStore {
  def apply(xa: Transactor[Task]): SqlAccountStore =
    new SqlAccountStore(xa)
}
