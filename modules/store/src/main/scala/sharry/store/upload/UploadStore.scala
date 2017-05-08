package sharry.store.upload

import java.time.Instant
import fs2.{Pipe, Strategy, Stream, Task}

import sharry.store.data.mime._
import sharry.store.data.sizes._
import sharry.store.range._
import sharry.store.data.{Alias, FileMeta, FileChunk, Upload, UploadFile, UploadInfo}

trait UploadStore {

  def createUpload(up: Upload): Stream[Task, Unit]

  def createUploadFile(uploadId: String, file: FileMeta, filename: String): Stream[Task, UploadFile]

  def deleteUpload(id: String, login: String): Stream[Task, Int]

  def updateMime(fileId: String, mimeType: MimeType): Stream[Task, Int]

  def addChunk(fc: FileChunk): Stream[Task, Unit]

  def chunkExists(uploadId: String, fileId: String, chunkNr: Int, chunkLength: Size): Stream[Task, Boolean]

  def listUploads(login: String): Stream[Task, Upload]

  def getUpload(id: String, login: String): Stream[Task, UploadInfo]

  def getPublishedUpload(id: String):  Stream[Task, UploadInfo]

  def publishUpload(id: String, login: String): Stream[Task, Either[String, String]]

  def getUploadByFileId(fileId: String, login: String): Stream[Task, (Upload, UploadInfo.File)]

  def getPublishedUploadByFileId(fileId: String): Stream[Task, (Upload, UploadInfo.File)]

  /** Fetch data using one connection per chunk. So connections are
    * closed immediately after reading a chunk. */
  def fetchData(range: RangeSpec): Pipe[Task, UploadInfo.File, Byte]

  /** Fetch data using one connection for the whole stream. It is closed
    * once the stream terminates. */
  def fetchData2(range: RangeSpec): Pipe[Task, UploadInfo.File, Byte]

  def zipAll(chunkSize: Int)(implicit S: Strategy): Pipe[Task, UploadInfo, Byte]

  def cleanup(invalidSince: Instant): Stream[Task,Int]

  def createAlias(alias: Alias): Stream[Task, Unit]

  def listAliases(login: String): Stream[Task, Alias]

  def getAlias(id: String): Stream[Task, Alias]

  def deleteAlias(id: String, login: String): Stream[Task, Int]

  def updateAlias(alias: Alias): Stream[Task, Int]
}
