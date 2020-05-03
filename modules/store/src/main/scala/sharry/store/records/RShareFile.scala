package sharry.store.records

import doobie._, doobie.implicits._
import sharry.common._
import sharry.store.doobie._
import sharry.store.doobie.DoobieMeta._

case class RShareFile(
    id: Ident,
    shareId: Ident,
    fileId: Ident,
    filename: Option[String],
    created: Timestamp,
    realSize: ByteSize
)

object RShareFile {

  val table = fr"share_file"

  object Columns {
    val id       = Column("id")
    val shareId  = Column("share_id")
    val fileId   = Column("file_id")
    val filename = Column("filename")
    val created  = Column("created")
    val realSize = Column("real_size")
    val all      = List(id, shareId, fileId, filename, created, realSize)
  }

  import Columns._

  def insert(v: RShareFile): ConnectionIO[Int] =
    Sql
      .insertRow(
        table,
        all,
        fr"${v.id},${v.shareId},${v.fileId},${v.filename},${v.created},${v.realSize}"
      )
      .update
      .run

  def getFileMetaId(sfId: Ident): ConnectionIO[Option[Ident]] =
    Sql.selectSimple(Seq(fileId), table, id.is(sfId)).query[Ident].option

  def findById(fileId: Ident): ConnectionIO[Option[RShareFile]] =
    Sql.selectSimple(all, table, id.is(fileId)).query[RShareFile].option

  def delete(shareFileId: Ident): ConnectionIO[Int] =
    Sql.deleteFrom(table, id.is(shareFileId)).update.run

  def deleteByFileId(fid: Ident): ConnectionIO[Int] =
    Sql.deleteFrom(table, fileId.is(fid)).update.run

  def setRealSize(fid: Ident, size: ByteSize): ConnectionIO[Int] =
    Sql.updateRow(table, id.is(fid), realSize.setTo(size)).update.run

  def addRealSize(fid: Ident, size: ByteSize): ConnectionIO[Int] =
    Sql.updateRow(table, id.is(fid), realSize.increment(size.bytes)).update.run
}
