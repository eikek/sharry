package sharry.store.upload

import java.time.Instant
import fs2.{Pipe, Stream}
import cats.effect.IO
import bitpeace.{FileChunk, RangeDef, MimetypeHint}
import scala.concurrent.ExecutionContext

import sharry.common.mime._
import sharry.common.sizes._
import sharry.common.data._
import sharry.store.data._

trait UploadStore {

  def createUpload(up: Upload): Stream[IO, Unit]

  def createUploadFile(uploadId: String, fileId: String, filename: String, clientFileId: String): Stream[IO, UploadFile]

  def deleteUpload(id: String, login: String): Stream[IO, Int]

  def updateMime(fileId: String, mimeType: MimeType): Stream[IO, Int]

  def updateTimestamp(uploadId: String, fileId: String, time: Instant): Stream[IO, Int]

  def addChunk(uploadId: String, fc: FileChunk, chunksize: Int, totalChunks: Int, hint: MimetypeHint): Stream[IO, FileMeta]

  def chunkExists(uploadId: String, fileId: String, chunkNr: Int, chunkLength: Size): Stream[IO, Boolean]

  def listUploads(login: String): Stream[IO, Upload]

  def getUpload(id: String, login: String): Stream[IO, UploadInfo]

  def getPublishedUpload(id: String):  Stream[IO, UploadInfo]

  def getUploadSize(id: String): Stream[IO, UploadSize]

  def publishUpload(id: String, login: String): Stream[IO, Either[String, String]]

  def unpublishUpload(id: String, login: String): Stream[IO,Either[String,Unit]]

  def getUploadByFileId(fileId: String, login: String): Stream[IO, (Upload, UploadInfo.File)]

  def getPublishedUploadByFileId(fileId: String): Stream[IO, (Upload, UploadInfo.File)]

  /** Fetch data using one connection per chunk. So connections are
    * closed immediately after reading a chunk. */
  def fetchData(range: RangeDef): Pipe[IO, UploadInfo.File, Byte]

  /** Fetch data using one connection for the whole stream. It is closed
    * once the stream terminates. */
  def fetchData2(range: RangeDef): Pipe[IO, UploadInfo.File, Byte]

  def zipAll(chunkSize: Int)(implicit EC: ExecutionContext): Pipe[IO, UploadInfo, Byte]

  def cleanup(invalidSince: Instant): Stream[IO,Int]

  def createAlias(alias: Alias): Stream[IO, Unit]

  def listAliases(login: String): Stream[IO, Alias]

  def getAlias(id: String): Stream[IO, Alias]

  /** Get an enabled alias whose referring account is enabled, too. */
  def getActiveAlias(id: String): Stream[IO, Alias]

  def deleteAlias(id: String, login: String): Stream[IO, Int]

  def updateAlias(alias: Alias, id: String): Stream[IO, Int]
}
