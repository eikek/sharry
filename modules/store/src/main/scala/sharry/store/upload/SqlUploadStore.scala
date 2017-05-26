package sharry.store.upload

import java.time.Instant
import fs2.{Pipe, Strategy, Stream, Task}
import doobie.imports._
import cats.implicits._

import sharry.store.range._
import sharry.common.mime._
import sharry.common.rng._
import sharry.common.sizes._
import sharry.common.streams
import sharry.common.zip
import sharry.store.data.{Alias, FileMeta, FileChunk, Upload, UploadFile, UploadInfo}
import sharry.store.binary.BinaryStore

class SqlUploadStore(xa: Transactor[Task], binaryStore: BinaryStore) extends UploadStore with SqlStatements {
  private val logger = com.typesafe.scalalogging.Logger(getClass)

  def createUpload(up: Upload): Stream[Task, Unit] =
    Stream.eval(insertUploadConfig(up).run.transact(xa)).map(_ => ())

  def deleteUpload(id: String, login: String): Stream[Task, Int] = {
    for {
      fileIds <- Stream.eval(sqlSelectFileIds(id).transact(xa))
      _ <- getUpload(id, login)
      n <- Stream.eval(sqlDeleteUpload(id, fileIds).transact(xa))
    } yield n
  }

  def createUploadFile(uploadId: String, file: FileMeta, filename: String): Stream[Task, UploadFile] =
    Stream.eval(insertUploadFile(uploadId, file, filename, 0, None).transact(xa))

  def updateMime(fileId: String, mimeType: MimeType): Stream[Task, Int] =
    Stream.eval(setFileMetaMimeType(fileId, mimeType).run.transact(xa))

  def updateTimestamp(uploadId: String, fileId: String, time: Instant): Stream[Task, Int] =
    Stream.eval(sqlSetUploadTimestamp(uploadId, fileId, time).transact(xa))

  def addChunk(fc: FileChunk): Stream[Task, Unit] =
    binaryStore.saveFileChunk(fc)

  def chunkExists(uploadId: String, fileId: String, chunkNr: Int, chunkLength: Size): Stream[Task, Boolean] =
    Stream.eval(sqlChunkExists(uploadId, fileId, chunkNr, chunkLength).transact(xa))

  def listUploads(login: String): Stream[Task, Upload] =
    sqlListUploads(login).transact(xa)

  def getUpload(id: String, login: String): Stream[Task, UploadInfo] =
    Stream.eval(sqlGetUploadInfo(id, login).transact(xa)).
      through(streams.optionToEmpty)

  def getPublishedUpload(id: String):  Stream[Task, UploadInfo] = {
    val update = sqlUpdateDownloadStats(id, 1, Instant.now).run
    val get = for {
      up <- sqlGetPublishedUpload(id)
      files <- up match {
        case Some(u) => sqlGetUploadFiles(u.id, u.login)
        case None => Nil.pure[ConnectionIO]
      }
    } yield up.map(UploadInfo(_, files))

    val resp = Stream.eval {
      for {
        up <- get.transact(xa)
        _ <- update.transact(xa)
      } yield up
    }
    resp.through(streams.optionToEmpty)
  }

  def publishUpload(id: String, login: String): Stream[Task, Either[String, String]] = {
    Stream.eval(sqlGetUpload(id, login).transact(xa)).
      through(streams.optionToEmpty).
      flatMap { up =>
        up.publishId match {
          case Some(publishId) =>
            Stream.emit(Left(s"The upload $id is already published ($publishId)"))
          case None =>
            val publishId = Gen.ident(32, 42).generate()
            Stream.eval(sqlPublishUpload(id, login, publishId, Instant.now, up.validity).run.transact(xa)).
              map(n => {
                if (n == 1) Right(publishId)
                else Left("Internal error, published more than one upload")
              })
        }
      }
  }

  def unpublishUpload(id: String, login: String): Stream[Task,Either[String,Unit]] =
    Stream.eval(sqlGetUpload(id, login).transact(xa)).
      through(streams.optionToEmpty).
      flatMap { up =>
        up.publishId match {
          case None =>
            Stream.emit(Left(s"The upload $id is not published already."))
          case Some(_) =>
            Stream.eval(sqlUnpublishUpload(id, login).run.transact(xa)).
              map(n =>
                if (n == 1) Right(())
                else Left("Internal error: unpublished more than one upload"))
        }
      }

  def getUploadByFileId(fileId: String, login: String): Stream[Task, (Upload, UploadInfo.File)] =
    Stream.eval(sqlGetUploadByFileId(fileId, login).transact(xa)).
      through(streams.optionToEmpty)

  def getPublishedUploadByFileId(fileId: String): Stream[Task, (Upload, UploadInfo.File)] =
    Stream.eval(sqlGetPublishedUploadByFileId(fileId).transact(xa)).
      through(streams.optionToEmpty)

  def fetchData(range: RangeSpec): Pipe[Task, UploadInfo.File, Byte] =
    _.map(_.meta).through(binaryStore.fetchData(range))

  def fetchData2(range: RangeSpec): Pipe[Task, UploadInfo.File, Byte] =
    _.map(_.meta).through(binaryStore.fetchData2(range))

  def zipAll(chunkSize: Int)(implicit S: Strategy): Pipe[Task, UploadInfo, Byte] =
    _.flatMap(info => Stream.emits(info.files)).
      map(f => f.filename -> Stream.emit(f).through(fetchData2(RangeSpec.all))).
      through(zip.zip(chunkSize))


  def cleanup(invalidSince: Instant): Stream[Task,Int] = {
    sqlListInvalidSince(invalidSince).transact(xa).flatMap { case (id, validUntil) =>
      logger.info(s"Cleanup invalid since $invalidSince removes upload $id (validUntil $validUntil")
      for {
        fileIds <- Stream.eval(sqlSelectFileIds(id).transact(xa))
        _ <- Stream.eval(sqlDeleteUpload(id, fileIds).transact(xa))
      } yield 1
    }
  }

  def createAlias(alias: Alias): Stream[Task, Unit] =
    Stream.eval(sqlInsertAlias(alias).run.map(_ => ()).transact(xa))

  def listAliases(login: String): Stream[Task, Alias] =
    sqlListAliases(login).transact(xa)

  def getAlias(id: String): Stream[Task, Alias] =
    Stream.eval(sqlGetAlias(id).transact(xa)).
      through(streams.optionToEmpty)

  def getActiveAlias(id: String): Stream[Task, Alias] =
    Stream.eval(sqlGetActiveAlias(id).transact(xa)).
      through(streams.optionToEmpty)

  def deleteAlias(id: String, login: String): Stream[Task, Int] =
    Stream.eval(sqlDeleteAlias(id, login).run.transact(xa))

  def updateAlias(alias: Alias): Stream[Task, Int] =
    Stream.eval(sqlUpdateAlias(alias).run.transact(xa))

}
