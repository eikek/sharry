package sharry.store.records

import cats.effect.Sync
import cats.implicits._
import fs2.Stream

import sharry.common._
import sharry.store.doobie.DoobieMeta._
import sharry.store.doobie._

import doobie._
import doobie.implicits._

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
    val id       = Column("id")
    val account  = Column("account_id")
    val name     = Column("name_")
    val validity = Column("validity")
    val enabled  = Column("enabled")
    val created  = Column("created")

    val all = List(id, account, name, validity, enabled, created)
  }

  def createNew[F[_]: Sync](
      account: Ident,
      name: String,
      validity: Duration,
      enabled: Boolean
  ): F[RAlias] =
    for {
      id  <- Ident.randomId[F]
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

  def findById(aliasId: Ident, accId: Ident): ConnectionIO[Option[RAlias]] =
    Sql
      .selectSimple(all, table, Sql.and(id.is(aliasId), account.is(accId)))
      .query[RAlias]
      .option

  def existsById(aliasId: Ident): ConnectionIO[Boolean] =
    Sql.selectCount(id, table, id.is(aliasId)).query[Int].map(_ > 0).unique

  def findAll(acc: Ident, nameQ: String): Stream[ConnectionIO, RAlias] = {
    val q =
      if (nameQ.isEmpty) Fragment.empty
      else name.like("%" + nameQ + "%")
    Sql.selectSimple(all, table, Sql.and(account.is(acc), q)).query[RAlias].stream
  }

  def delete(aliasId: Ident, accId: Ident): ConnectionIO[Int] =
    Sql.deleteFrom(table, Sql.and(account.is(accId), id.is(aliasId))).update.run

  def deleteForAccount(accountId: Ident): ConnectionIO[Int] =
    Sql.deleteFrom(table, account.is(accountId)).update.run
}
