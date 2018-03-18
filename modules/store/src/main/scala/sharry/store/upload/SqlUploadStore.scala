package sharry.store.upload

import java.time.Instant
import fs2.{Pipe, Stream}
import cats.effect.IO
import doobie._, doobie.implicits._
import cats.implicits._
import org.log4s._
import bitpeace.{Bitpeace, BitpeaceConfig, MimetypeHint, FileChunk, RangeDef}
import scala.concurrent.ExecutionContext

import sharry.common.mime._
import sharry.common.rng._
import sharry.common.sizes._
import sharry.common.streams
import sharry.common.zip
import sharry.common.data._
import sharry.store.data._

class SqlUploadStore(xa: Transactor[IO], val config: BitpeaceConfig[IO]) extends UploadStore with SqlStatements {
  private[this] val logger = getLogger

  private val binaryStore: Bitpeace[IO] = Bitpeace(config, xa)

  def createUpload(up: Upload): Stream[IO, Unit] =
    Stream.eval(insertUploadConfig(up).run.transact(xa)).map(_ => ())

  def deleteUpload(id: String, login: String): Stream[IO, Int] = {
    for {
      fileIds <- Stream.eval(sqlSelectFileIds(id).transact(xa))
      _ <- getUpload(id, login)
      n <- Stream.eval(sqlDeleteUpload(id, fileIds).transact(xa))
    } yield n
  }

  def createUploadFile(uploadId: String, fileId: String, filename: String, clientFileId: String): Stream[IO, UploadFile] =
    Stream.eval(insertUploadFile(uploadId, fileId, filename, 0, None, clientFileId).transact(xa))

  def updateMime(fileId: String, mimeType: MimeType): Stream[IO, Int] =
    Stream.eval(setFileMetaMimeType(fileId, mimeType).run.transact(xa))

  def updateTimestamp(uploadId: String, fileId: String, time: Instant): Stream[IO, Int] =
    Stream.eval(sqlSetUploadTimestamp(uploadId, fileId, time).transact(xa))

  def addChunk(uploadId: String, fc: FileChunk, chunksize: Int, totalChunks: Int, hint: MimetypeHint): Stream[IO, FileMeta] =
    binaryStore.addChunk(fc, chunksize, totalChunks, hint).map(_.result.asSharry)

  def chunkExists(uploadId: String, fileId: String, chunkNr: Int, chunkLength: Size): Stream[IO, Boolean] =
    Stream.eval(sqlChunkExists(uploadId, fileId, chunkNr, chunkLength).transact(xa))

  def listUploads(login: String): Stream[IO, Upload] =
    sqlListUploads(login).transact(xa)

  def getUpload(id: String, login: String): Stream[IO, UploadInfo] =
    Stream.eval(sqlGetUploadInfo(id, login).transact(xa)).
      through(streams.optionToEmpty)

  def getPublishedUpload(id: String):  Stream[IO, UploadInfo] = {
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

  def getUploadSize(id: String): Stream[IO, UploadSize] =
    Stream.eval(sqlGetUploadSizeFromChunks(id).transact(xa))

  def publishUpload(id: String, login: String): Stream[IO, Either[String, String]] = {
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

  def unpublishUpload(id: String, login: String): Stream[IO,Either[String,Unit]] =
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

  def getUploadByFileId(fileId: String, login: String): Stream[IO, (Upload, UploadInfo.File)] =
    Stream.eval(sqlGetUploadByFileId(fileId, login).transact(xa)).
      through(streams.optionToEmpty)

  def getPublishedUploadByFileId(fileId: String): Stream[IO, (Upload, UploadInfo.File)] =
    Stream.eval(sqlGetPublishedUploadByFileId(fileId).transact(xa)).
      through(streams.optionToEmpty)

  def fetchData(range: RangeDef): Pipe[IO, UploadInfo.File, Byte] =
    _.map(_.meta.asBitpeace).through(binaryStore.fetchData(range))

  def fetchData2(range: RangeDef): Pipe[IO, UploadInfo.File, Byte] =
    _.map(_.meta.asBitpeace).through(binaryStore.fetchData2(range))

  def zipAll(chunkSize: Int)(implicit EC: ExecutionContext): Pipe[IO, UploadInfo, Byte] =
    _.flatMap(info => Stream.emits(info.files)).
      map(f => f.filename -> Stream.emit(f).covary[IO].through(fetchData2(RangeDef.all))).
      through(zip.zip(chunkSize))


  def cleanup(invalidSince: Instant): Stream[IO,Int] = {
    sqlListInvalidSince(invalidSince).transact(xa).flatMap { case (id, validUntil) =>
      logger.info(s"Cleanup invalid since $invalidSince removes upload $id (validUntil $validUntil")
      for {
        fileIds <- Stream.eval(sqlSelectFileIds(id).transact(xa))
        _ <- Stream.eval(sqlDeleteUpload(id, fileIds).transact(xa))
      } yield 1
    }
  }

  def createAlias(alias: Alias): Stream[IO, Unit] =
    Stream.eval(sqlInsertAlias(alias).run.map(_ => ()).transact(xa))

  def listAliases(login: String): Stream[IO, Alias] =
    sqlListAliases(login).transact(xa)

  def getAlias(id: String): Stream[IO, Alias] =
    Stream.eval(sqlGetAlias(id).transact(xa)).
      through(streams.optionToEmpty)

  def getActiveAlias(id: String): Stream[IO, Alias] =
    Stream.eval(sqlGetActiveAlias(id).transact(xa)).
      through(streams.optionToEmpty)

  def deleteAlias(id: String, login: String): Stream[IO, Int] =
    Stream.eval(sqlDeleteAlias(id, login).run.transact(xa))

  def updateAlias(alias: Alias, id: String): Stream[IO, Int] =
    Stream.eval(sqlUpdateAlias(alias, id).run.transact(xa))

}
