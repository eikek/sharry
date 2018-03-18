package sharry.store.account

import fs2.Stream
import cats.effect.IO
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

  def accountExists(login: String): Stream[IO,Boolean]

  def getAccount(login: String): Stream[IO,Account]

  def createAccount(account: Account): Stream[IO,Unit]

  def updateAccount(account: Account): Stream[IO,Boolean]

  def setAccountEnabled(login: String, flag: Boolean): Stream[IO,Boolean]

  def updatePassword(login: String, password: Option[String]): Stream[IO,Boolean]

  def updateEmail(login: String, email: Option[String]): Stream[IO,Boolean]

  def deleteAccount(login: String): Stream[IO,Boolean]

  def listLogins(q: String, limit: Option[Limit]): Stream[IO,String]

}
