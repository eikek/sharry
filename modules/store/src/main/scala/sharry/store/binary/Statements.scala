package sharry.store.binary

import com.typesafe.scalalogging.Logger
import doobie.imports._
import scodec.bits.ByteVector
import sharry.store.data._
import sharry.store.columns._

trait Statements {

  implicit def logHandler(implicit l: Logger) = logSql(l)

  def insertChunk(ch: FileChunk) =
    sql"""INSERT INTO FileChunk VALUES (${ch.fileId}, ${ch.chunkNr}, ${ch.chunkLength}, ${ch.chunkData})"""
      .update

  def updateChunkId(old: String, id: String) =
    sql"""UPDATE FileChunk SET fileId = $id WHERE fileId = $old"""
      .update

  def selectChunkData(id: String, offset: Option[Int] = None, limit: Option[Int] = None) =
    sql"""SELECT chunkData FROM FileChunk WHERE fileId = $id"""
      .offset(offset)
      .limit(limit)
      .query[ByteVector]

  def selectChunks(id: String, offset: Option[Int] = None, limit: Option[Int] = None) =
    sql"""SELECT fileId, chunkNr, chunkData FROM FileChunk WHERE fileId = $id"""
      .offset(offset)
      .limit(limit)
      .query[FileChunk]

  def deleteChunks(id: String) =
    sql"""DELETE FROM FileChunk WHERE fileId = $id"""
      .update

  def deleteFileMeta(id: String) =
    sql"""DELETE FROM FileMeta WHERE id = $id"""
      .update

  def insertFileMeta(fm: FileMeta) =
    sql"""INSERT INTO FileMeta VALUES (
      ${fm.id}, ${fm.timestamp}, ${fm.mimetype}, ${fm.length}, ${fm.chunks}, ${fm.chunksize}
    )
    """.update

  def fileExists(id: String) =
    sql"""SELECT id FROM FileMeta WHERE id = $id""".query[String].option

  def selectFileMeta(id: String) =
    sql"""SELECT id, timestamp, mimetype, length, chunks, chunksize FROM FileMeta WHERE id = $id"""
      .query[FileMeta]
      .option
}
