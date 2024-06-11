package sharry.store.records

import cats.effect.Sync
import cats.implicits.*
import fs2.Stream

import sharry.common.*
import sharry.store.doobie.*
import sharry.store.doobie.DoobieMeta.*

import doobie.*
import doobie.implicits.*

case class RAlias(
    id: Ident,
    account: Ident,
    name: String,
    validity: Duration,
    enabled: Boolean,
    created: Timestamp
)

object RAlias {
  val table = fr"alias_"

  object Columns {
    val id = Column("id")
    val account = Column("account_id")
    val name = Column("name_")
    val validity = Column("validity")
    val enabled = Column("enabled")
    val created = Column("created")

    val all = List(id, account, name, validity, enabled, created)
  }

  def createNew[F[_]: Sync](
      account: Ident,
      name: String,
      validity: Duration,
      enabled: Boolean
  ): F[RAlias] =
    for {
      id <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RAlias(id, account, name, validity, enabled, now)

  import Columns._

  def insert(v: RAlias): ConnectionIO[Int] = {
    val sql = Sql.insertRow(
      table,
      all,
      fr"${v.id},${v.account},${v.name},${v.validity},${v.enabled},${v.created}"
    )
    sql.update.run
  }

  def update(aid: Ident, acc: Ident, v: RAlias): ConnectionIO[Int] =
    Sql
      .updateRow(
        table,
        Sql.and(id.is(aid), account.is(acc)),
        Sql.commas(
          id.setTo(v.id),
          name.setTo(v.name),
          validity.setTo(v.validity),
          enabled.setTo(v.enabled)
        )
      )
      .update
      .run

  def findById(aliasId: Ident, accId: Ident): ConnectionIO[Option[(RAlias, Ident)]] = {
    val aId = "a" :: id

    find0(accId, aId.is(aliasId)).option
  }

  def findAll(acc: Ident, nameQ: String): Stream[ConnectionIO, (RAlias, Ident)] = {
    val aName = "a" :: name

    val q =
      if (nameQ.isEmpty) Fragment.empty
      else aName.like("%" + nameQ + "%")

    find0(acc, q).stream
  }

  private def find0(accId: Ident, cond: Fragment) = {
    val aId = "a" :: id
    val aAccount = "a" :: account
    val cId = "c" :: RAccount.Columns.id
    val cLogin = "c" :: RAccount.Columns.login

    val from =
      table ++ fr"a" ++
        fr"INNER JOIN" ++ RAccount.table ++ fr"c ON" ++ aAccount.is(cId)

    Sql
      .selectSimple(
        all.map("a" :: _) :+ cLogin,
        from,
        Sql.and(
          Sql.or(aAccount.is(accId), aId.in(RAliasMember.aliasMemberOf(accId))),
          cond
        )
      )
      .query[(RAlias, Ident)]
  }

  def existsById(aliasId: Ident): ConnectionIO[Boolean] =
    Sql.selectCount(id, table, id.is(aliasId)).query[Int].map(_ > 0).unique

  def delete(aliasId: Ident, accId: Ident): ConnectionIO[Int] =
    Sql.deleteFrom(table, Sql.and(account.is(accId), id.is(aliasId))).update.run

  def deleteForAccount(accountId: Ident): ConnectionIO[Int] =
    Sql.deleteFrom(table, account.is(accountId)).update.run
}
