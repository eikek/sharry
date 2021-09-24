package sharry.store.records

import cats.effect.Sync
import cats.implicits._

import sharry.common._
import sharry.store.doobie.DoobieMeta._
import sharry.store.doobie._

import doobie._
import doobie.implicits._

case class RAliasMember(
    id: Ident,
    aliasId: Ident,
    accountId: Ident
)

object RAliasMember {
  val table = fr"alias_member"

  object Columns {
    val id = Column("id")
    val aliasId = Column("alias_id")
    val accountId = Column("account_id")

    val all = List(id, aliasId, accountId)
  }

  def createNew[F[_]: Sync](
      aliasId: Ident,
      accountId: Ident
  ): F[RAliasMember] =
    for {
      id <- Ident.randomId[F]
    } yield RAliasMember(id, aliasId, accountId)

  import Columns._

  def insert(v: RAliasMember): ConnectionIO[Int] = {
    val sql = Sql.insertRow(
      table,
      all,
      fr"${v.id},${v.aliasId},${v.accountId}"
    )
    sql.update.run
  }

  def insertForAlias(aId: Ident, accountIds: List[Ident]): ConnectionIO[Int] =
    for {
      all <- accountIds.traverse(accId => createNew[ConnectionIO](aId, accId))
      n <- all.traverse(insert).map(_.sum)
    } yield n

  def updateForAlias(aId: Ident, logins: List[Ident]): ConnectionIO[Int] =
    for {
      _ <- deleteForAlias(aId)
      n <- insertForAlias(aId, logins)
    } yield n

  def deleteForAlias(aId: Ident): ConnectionIO[Int] =
    Sql.deleteFrom(table, aliasId.is(aId)).update.run

  def update(v: RAliasMember): ConnectionIO[Int] =
    Sql
      .updateRow(
        table,
        Sql.and(id.is(v.id)),
        Sql.commas(
          aliasId.setTo(v.aliasId),
          accountId.setTo(v.accountId)
        )
      )
      .update
      .run

  def findForAlias(aId: Ident): ConnectionIO[List[(RAliasMember, Ident)]] = {
    val accId = "a" :: RAccount.Columns.id
    val aLogin = "a" :: RAccount.Columns.login
    val mAccount = "m" :: RAliasMember.Columns.accountId
    val mAlias = "m" :: RAliasMember.Columns.aliasId

    val from =
      table ++ fr"as m INNER JOIN" ++ RAccount.table ++ fr"as a ON" ++ accId.is(mAccount)

    val cols =
      Columns.all.map("m" :: _) ++ Seq(aLogin)
    Sql
      .selectSimple(cols, from, mAlias.is(aId))
      .query[(RAliasMember, Ident)]
      .to[List]
  }

  def delete(aid: Ident): ConnectionIO[Int] =
    Sql.deleteFrom(table, id.is(aid)).update.run

  /** A query to select all aliasIds of the given account */
  def aliasMemberOf(accId: Ident): Fragment =
    Sql.selectSimple(
      RAliasMember.Columns.aliasId.f,
      RAliasMember.table,
      RAliasMember.Columns.accountId.is(accId)
    )
}
