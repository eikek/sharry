package sharry.store.records

import cats.effect.Sync
import cats.implicits.*

import sharry.common.*
import sharry.store.doobie.*
import sharry.store.doobie.DoobieMeta.*

import doobie.*
import doobie.implicits.*

case class RInvitation(id: Ident, created: Timestamp) {}

object RInvitation {

  val table = fr"invitation"

  object Columns {
    val id = Column("id")
    val created = Column("created")
    val all = List(id, created)
  }
  import Columns._

  def generate[F[_]: Sync]: F[RInvitation] =
    for {
      c <- Timestamp.current[F]
      i <- Ident.randomId[F]
    } yield RInvitation(i, c)

  def insert(v: RInvitation): ConnectionIO[Int] =
    Sql.insertRow(table, all, fr"${v.id},${v.created}").update.run

  def insertNew: ConnectionIO[RInvitation] =
    generate[ConnectionIO].flatMap(v => insert(v).map(_ => v))

  def findById(invite: Ident): ConnectionIO[Option[RInvitation]] =
    Sql.selectSimple(all, table, id.is(invite)).query[RInvitation].option

  def delete(invite: Ident): ConnectionIO[Int] =
    Sql.deleteFrom(table, id.is(invite)).update.run

  def useInvite(invite: Ident, minCreated: Timestamp): ConnectionIO[Boolean] = {
    val get =
      Sql
        .selectCount(id, table, Sql.and(id.is(invite), created.isGt(minCreated)))
        .query[Int]
        .unique
    for {
      inv <- get
      _ <- delete(invite)
    } yield inv > 0
  }

  def deleteOlderThan(minCreated: Timestamp): ConnectionIO[Int] =
    Sql.deleteFrom(table, created.isLt(minCreated)).update.run
}
