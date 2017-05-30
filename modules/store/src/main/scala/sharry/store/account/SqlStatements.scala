package sharry.store.account

import org.log4s._
import doobie.imports._
import sharry.store.data._
import sharry.store.Limit
import sharry.store.columns._

trait SqlStatements {

  implicit def logHandler(implicit l: Logger) = logSql(l)

  def insertAccount(a: Account) =
    sql"""INSERT INTO Account (login,password,email,admin,enabled,extern) VALUES(
      ${a.login}, ${a.password}, ${a.email}, ${a.admin}, ${a.enabled}, ${a.extern}
    )""".update

  def selectAccount(login: String) =
    sql"""SELECT login,password,email,enabled,admin,extern FROM Account WHERE login = ${login}""".
      query[Account].
      option

  def selectLogins(partial: String, limit: Option[Limit]) = {
    val q = {
      val s = fr"SELECT login FROM Account"
      val term = s"%${partial}%"
      if (partial.isEmpty) s ++ fr"ORDER BY login"
      else s ++ fr"WHERE login like $term ORDER BY login"
    }
    limit match {
      case None =>
        q.query[String]
      case Some(l) =>
        (q ++ fr"LIMIT ${l.limit} OFFSET ${l.offset}").query[String]
    }
  }


  def existsAccount(login: String) =
    sql"""SELECT count(login) FROM Account WHERE login = ${login}""".
      query[Int].
      unique.
      map(_ > 0)


  def deleteAccountSql(login: String) =
    sql"""DELETE FROM Account WHERE login = $login""".update

  def updateAccountSql(a: Account) =
    sql"""UPDATE Account SET
            password = ${a.password},
            email = ${a.email},
            admin = ${a.admin},
            enabled = ${a.enabled},
            extern = ${a.extern}
          WHERE login = ${a.login}""".update

  def updateEnabledSql(login: String, flag: Boolean) =
    sql"""UPDATE Account SET enabled = $flag WHERE login = $login""".update

  def sqlUpdateEmail(login: String, email: Option[String]) =
    sql"""UPDATE Account SET email = $email WHERE login = $login""".update

  def sqlUpdatePassword(login: String, password: Option[String]) =
    sql"""UPDATE Account SET password = $password WHERE login = $login AND extern = false""".update

}
