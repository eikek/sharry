package sharry.store.account

import fs2.{Stream, Task}
import sharry.common.data.Account
import sharry.store.Limit

/** On top of `ContentStore` associate accounts to data.
  *
  * While stored data in sitebag is considered public, the association
  * of a data to an account is not. This store is for associating user
  * accounts to stored data. The data itself is shared across
  * accounts.
  */
trait AccountStore {

  def accountExists(login: String): Stream[Task,Boolean]

  def getAccount(login: String): Stream[Task,Account]

  def createAccount(account: Account): Stream[Task,Unit]

  def updateAccount(account: Account): Stream[Task,Boolean]

  def setAccountEnabled(login: String, flag: Boolean): Stream[Task,Boolean]

  def updatePassword(login: String, password: Option[String]): Stream[Task,Boolean]

  def updateEmail(login: String, email: Option[String]): Stream[Task,Boolean]

  def deleteAccount(login: String): Stream[Task,Boolean]

  def listLogins(q: String, limit: Option[Limit]): Stream[Task,String]

}
