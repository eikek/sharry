package sharry.store.records

import cats.implicits.*
import fs2.Stream

import sharry.common.*
import sharry.store.doobie.*
import sharry.store.doobie.DoobieMeta.*

import doobie.*
import doobie.implicits.*

case class RAccount(
    id: Ident,
    login: CIIdent,
    source: AccountSource,
    state: AccountState,
    password: Password,
    email: Option[String],
    admin: Boolean,
    loginCount: Int,
    lastLogin: Option[Timestamp],
    created: Timestamp
) {

  def accountId(alias: Option[Ident]): AccountId =
    AccountId(id, login.value, admin, alias)
}

object RAccount {
  val table = fr"account_"

  object Columns {
    val id = Column("id")
    val login = Column("login")
    val source = Column("source")
    val state = Column("state")
    val password = Column("password")
    val email = Column("email")
    val admin = Column("admin")
    val loginCount = Column("logincount")
    val lastLogin = Column("lastlogin")
    val created = Column("created")

    val all = List(
      id,
      login,
      source,
      state,
      password,
      email,
      admin,
      loginCount,
      lastLogin,
      created
    )
  }

  import Columns._

  def insert(v: RAccount, label: String): ConnectionIO[Int] = {
    val sql = Sql.insertRow(
      table,
      all,
      fr"${v.id},${v.login},${v.source},${v.state},${v.password},${v.email},${v.admin},${v.loginCount},${v.lastLogin},${v.created}"
    )
    sql.updateWithLabel(label).run
  }

  def update(aid: Ident, v: ModAccount): ConnectionIO[Int] = {
    val up1 = Sql.updateRow(
      table,
      Sql.and(id.is(aid), source.is(AccountSource.intern)),
      Sql.commas(
        state.setTo(v.state),
        email.setTo(v.email),
        admin.setTo(v.admin),
        password.setTo(v.password.getOrElse(Password.empty))
      )
    )

    val up2 = Sql.updateRow(
      table,
      Sql.and(id.is(aid), source.is(AccountSource.intern)),
      Sql.commas(state.setTo(v.state), email.setTo(v.email), admin.setTo(v.admin))
    )

    val up3 = Sql.updateRow(
      table,
      Sql.and(id.is(aid), source.isNot(AccountSource.intern)),
      Sql.commas(state.setTo(v.state), email.setTo(v.email), admin.setTo(v.admin))
    )

    for {
      n <- if (v.password.nonEmpty) up1.update.run else up2.update.run
      k <- if (n == 0) up3.update.run else 0.pure[ConnectionIO]
    } yield n + k
  }

  def setEmail(aid: Ident, v: Option[String]): ConnectionIO[Int] =
    Sql.updateRow(table, id.is(aid), email.setTo(v)).update.run

  def updatePassword(aid: Ident, pw: Password): ConnectionIO[Int] =
    Sql.updateRow(table, id.is(aid), password.setTo(pw)).update.run

  def updateStatsById(accId: Ident): ConnectionIO[Int] =
    Sql.currentTime.flatMap(t =>
      Sql
        .updateRow(
          table,
          id.is(accId),
          Sql.commas(
            loginCount.increment(1),
            lastLogin.setTo(t)
          )
        )
        .update
        .run
    )

  def findByLogin(user: Ident): ConnectionIO[Option[RAccount]] =
    Sql.selectSimple(all, table, login.is(CIIdent(user))).query[RAccount].option

  def findById(uid: Ident): ConnectionIO[Option[RAccount]] =
    Sql.selectSimple(all, table, id.is(uid)).query[RAccount].option

  def findByAlias(alias: Ident): ConnectionIO[Option[RAccount]] = {
    val aliasId = "n" :: RAlias.Columns.id
    val aliasEnabled = "n" :: RAlias.Columns.enabled
    val aliasAccount = "n" :: RAlias.Columns.account
    val accId = "a" :: Columns.id
    val from =
      table ++ fr"a INNER JOIN" ++ RAlias.table ++ fr"n ON" ++ accId.is(aliasAccount)
    Sql
      .selectSimple(
        all.map("a" :: _),
        from,
        Sql.and(aliasId.is(alias), aliasEnabled.is(true))
      )
      .query[RAccount]
      .option

  }

  def existsByLogin(user: Ident): ConnectionIO[Boolean] =
    Sql.selectCount(login, table, login.is(CIIdent(user))).query[Int].map(_ > 0).unique

  def findAll(loginQ: String): Stream[ConnectionIO, RAccount] = {
    val q =
      if (loginQ.isEmpty) Fragment.empty
      else login.like("%" + loginQ + "%")
    Sql.selectSimple(all, table, q).query[RAccount].stream
  }

  def delete(accountId: Ident): ConnectionIO[Int] =
    Sql.deleteFrom(table, id.is(accountId)).update.run
}
