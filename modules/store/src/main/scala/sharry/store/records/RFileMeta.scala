package sharry.store.records

import cats.implicits._

import sharry.common._
import sharry.store.doobie.DoobieMeta._
import sharry.store.doobie._

import doobie._
import doobie.implicits._
import scodec.bits.ByteVector

case class RFileMeta(
    id: Ident,
    created: Timestamp,
    mimetype: String,
    length: ByteSize,
    checksum: ByteVector
) {}

object RFileMeta {

  val table = fr"filemeta"

  object Columns {
    val id = Column("file_id")
    val created = Column("created")
    val mimetype = Column("mimetype")
    val length = Column("length")
    val checksum = Column("checksum")

    val all = List(id, created, mimetype, length, checksum)
  }

  def insert(r: RFileMeta): ConnectionIO[Int] =
    Sql
      .insertRow(
        table,
        Columns.all,
        sql"${r.id}, ${r.created}, ${r.mimetype}, ${r.length}, ${r.checksum}"
      )
      .update
      .run

  def update(r: RFileMeta): ConnectionIO[Int] =
    Sql
      .updateRow(
        table,
        Columns.id.is(r.id),
        Sql.commas(
          Columns.checksum.setTo(r.checksum),
          Columns.mimetype.setTo(r.mimetype),
          Columns.length.setTo(r.length)
        )
      )
      .update
      .run

  def upsert(r: RFileMeta): ConnectionIO[Int] =
    for {
      un <- update(r)
      in <-
        if (un > 0) un.pure[ConnectionIO]
        else insert(r)
    } yield un + in

  def findById(id: Ident): ConnectionIO[Option[RFileMeta]] =
    Sql.selectSimple(Columns.all, table, Columns.id.is(id)).query[RFileMeta].option

  def updateCreated(id: Ident, created: Timestamp): ConnectionIO[Int] =
    Sql.updateRow(table, Columns.id.is(id), Columns.created.setTo(created)).update.run

  def updateChecksum(id: Ident, checksum: ByteVector): ConnectionIO[Int] =
    Sql.updateRow(table, Columns.id.is(id), Columns.checksum.setTo(checksum)).update.run

  def delete(id: Ident): ConnectionIO[Int] =
    Sql.deleteFrom(table, Columns.id.is(id)).update.run
}
