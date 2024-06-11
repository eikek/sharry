package sharry.store.records

import sharry.common.*
import sharry.store.doobie.*
import sharry.store.doobie.DoobieMeta.*

import doobie.*
import doobie.implicits.*

case class RShare(
    id: Ident,
    accountId: Ident,
    aliasId: Option[Ident],
    name: Option[String],
    validity: Duration,
    maxViews: Int,
    password: Option[Password],
    description: Option[String],
    created: Timestamp
)

object RShare {

  val table = fr"share"

  object Columns {

    val id = Column("id")
    val accountId = Column("account_id")
    val aliasId = Column("alias_id")
    val name = Column("name_")
    val validity = Column("validity")
    val maxViews = Column("max_views")
    val password = Column("password")
    val description = Column("description")
    val created = Column("created")

    val all = List(
      id,
      accountId,
      aliasId,
      name,
      validity,
      maxViews,
      password,
      description,
      created
    )
  }

  import Columns._

  def insert(v: RShare): ConnectionIO[Int] =
    Sql
      .insertRow(
        table,
        all,
        fr"${v.id},${v.accountId},${v.aliasId},${v.name}," ++
          fr"${v.validity},${v.maxViews},${v.password}," ++
          fr"${v.description},${v.created}"
      )
      .update
      .run

  def getDuration(share: Ident): ConnectionIO[Duration] =
    Sql.selectSimple(Seq(validity), table, id.is(share)).query[Duration].unique

  def delete(sid: Ident): ConnectionIO[Int] =
    Sql.deleteFrom(table, id.is(sid)).update.run

  def getAllByAccount(accId: Ident): ConnectionIO[Vector[Ident]] =
    Sql
      .selectSimple(Seq(id), table, accountId.is(accId))
      .query[Ident]
      .to[Vector]

}
