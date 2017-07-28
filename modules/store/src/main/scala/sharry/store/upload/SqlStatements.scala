package sharry.store.upload

import java.time.{Duration, Instant}
import cats.data.NonEmptyList
import cats.implicits._
import doobie.imports._
import org.log4s._

import sharry.common.mime._
import sharry.common.sizes._
import sharry.store.columns._
import sharry.store.binary.Statements
import sharry.store.data._

trait SqlStatements extends Statements {

  private[this] val logger = getLogger
  private implicit val logHandler = logSql(logger)

  def insertUploadConfig(uc: Upload) = {
    // if this is an upload through an alias we set the „publishUntil”
    // field using the given validity so these uploads are garbage
    // collected although not published. If a user chooses to publish
    // this upload, this date is overwritten.
    //TODO: introduce a global validity for non-published uploads
    val until = uc.alias match {
      case Some(a) => Some(Instant.now plus uc.validity)
      case None => uc.validUntil
    }
    sql"""INSERT INTO Upload VALUES (
            ${uc.id}, ${uc.login}, ${uc.alias}, ${uc.description}, ${uc.validity},
            ${uc.maxDownloads}, ${uc.password}, ${uc.created},
            ${uc.downloads}, ${uc.lastDownload}, ${uc.publishId}, ${uc.publishDate}, ${until})""".update
  }

  def sqlSetUploadTimestamp(uploadId: String, fileId: String, time: Instant) =
    for {
      a <- sql"""UPDATE FileMeta SET timestamp = $time WHERE id = $fileId""".update.run
      b <- sql"""UPDATE Upload SET created = $time WHERE id = $uploadId""".update.run
    } yield a + b

  def setFileMetaMimeType(fileId: String, mimetype: MimeType) =
    sql"""UPDATE FileMeta SET mimetype = ${mimetype.asString} WHERE id = $fileId""".update

  def sqlChunkExists(uploadId: String, fileId: String, chunkNr: Int, chunkLength: Size) = {
    val check = sql"""SELECT count(*) FROM UploadFile AS uf
            INNER JOIN FileChunk AS fc ON uf.fileId = fc.fileId
            WHERE uf.uploadId = $uploadId AND uf.fileId = $fileId AND fc.chunknr = $chunkNr""".
      query[Int].
      unique.
      map(_ > 0)

    for {
      b <- check
      f <- if (b) sqlChunkLengthCheckOrRemove(fileId, chunkNr, chunkLength) else b.pure[ConnectionIO]
    } yield f
  }

  def sqlChunkLengthCheckOrRemove(fileId: String, chunkNr: Int, chunkLength: Size) = {
    val query = sql"""SELECT count(*) FROM FileChunk
                      WHERE fileId = $fileId AND chunknr = $chunkNr AND length(chunkData) != ${chunkLength.toBytes}""".
      query[Int].unique

    val delete = sql"""DELETE FROM FileChunk WHERE fileId = $fileId AND chunknr = $chunkNr""".update.run

    for {
      n <- query
      _ <- if (n == 1) delete else 0.pure[ConnectionIO]
    } yield n == 0
  }

  def insertUploadFile(f: UploadFile): Update0 =
    sql"""INSERT INTO UploadFile VALUES (${f.uploadId}, ${f.fileId}, ${f.filename}, ${f.downloads}, ${f.lastDownload})""".update

  def insertUploadFile(id: String, fm: FileMeta, filename: String, downloads: Int, lastDownload: Option[Instant]): ConnectionIO[UploadFile] = {
    val uf = UploadFile(id, fm.id, filename, downloads, lastDownload)
    for {
      _ <- insertFileMeta(fm).run
      _ <- insertUploadFile(uf).run
    } yield uf
  }

  def sqlListUploads(login: String) =
    sql"""SELECT up.id,up.login,up.validity,up.maxdownloads,up.alias,up.description,up.password,up.created,up.downloads,up.lastDownload,up.publishId,up.publishDate,al.name
          FROM Upload as up LEFT OUTER JOIN Alias as al ON up.alias = al.id
          WHERE up.login = $login ORDER BY created DESC""".
      query[Upload].
      process

  def sqlGetUpload(id: String, login: String) =
    sql"""SELECT up.id,up.login,up.validity,up.maxdownloads,up.alias,up.description,up.password,up.created,up.downloads,up.lastDownload,up.publishId,up.publishDate,al.name
          FROM Upload as up LEFT OUTER JOIN Alias as al ON up.alias = al.id
          WHERE up.id = $id AND up.login = $login""".
      query[Upload].
      option

  def sqlGetPublishedUpload(id: String) =
    sql"""SELECT up.id,up.login,up.validity,up.maxdownloads,up.alias,up.description,up.password,up.created,up.downloads,up.lastDownload,up.publishId,up.publishDate,al.name
          FROM Upload as up LEFT OUTER JOIN Alias as al ON up.alias = al.id
          WHERE up.publishId = $id""".
      query[Upload].
      option

  def sqlGetPublishedUploadByFileId(fileId: String) =
    sql"""SELECT up.id,up.login,up.validity,up.maxdownloads,up.alias,up.description,up.password,up.created,up.downloads,up.lastDownload,up.publishId,up.publishDate,al.name,
                 fm.*, uf.filename
          FROM Upload AS up
          INNER JOIN UploadFile AS uf ON uf.uploadId = up.id AND uf.fileId = $fileId
          INNER JOIN FileMeta AS fm ON fm.id = uf.fileId
          LEFT OUTER JOIN Alias as al ON up.alias = al.id
          WHERE up.publishId is not null""".
      query[(Upload, UploadInfo.File)].
      option

  def sqlGetUploadByFileId(fileId: String, login: String) =
    sql"""SELECT up.id,up.login,up.validity,up.maxdownloads,up.alias,up.description,up.password,up.created,up.downloads,up.lastDownload,up.publishId,up.publishDate,al.name,
                 fm.*, uf.filename
          FROM Upload AS up
          INNER JOIN UploadFile AS uf ON uf.uploadId = up.id AND uf.fileId = $fileId
          INNER JOIN FileMeta AS fm ON fm.id = uf.fileId
          LEFT OUTER JOIN Alias AS al ON up.alias = al.id
          WHERE up.login = $login""".
      query[(Upload, UploadInfo.File)].
      option

  def sqlGetUploadFiles(id: String, login: String) =
    sql"""SELECT fm.*, uf.filename from UploadFile AS uf
          INNER JOIN FileMeta AS fm ON uf.fileId = fm.id
          INNER JOIN Upload AS up ON up.id = uf.uploadId
          WHERE uf.uploadId = $id AND up.login = $login""".
      query[UploadInfo.File].
      list

  def sqlGetUploadInfo(id: String, login: String) =
    for {
      upload <- sqlGetUpload(id, login)
      files <- sqlGetUploadFiles(id, login)
    } yield upload.map(up => UploadInfo(up, files))

  def sqlPublishUpload(id: String, login: String, publishId: String, publishDate: Instant, valid: Duration) =
    sql"""UPDATE Upload SET publishId = $publishId, publishDate = $publishDate, publishUntil = ${publishDate.plus(valid)}
          WHERE publishId is null AND id = $id AND login = $login""".
      update

  def sqlUnpublishUpload(id: String, login: String) =
    sql"""UPDATE Upload SET publishId = null, publishDate = null, publishUntil = null
          WHERE id = $id AND login = $login""".
      update

  def sqlUpdateDownloadStats(publishId: String, inc: Int, last: Instant) =
    sql"""UPDATE Upload SET downloads = downloads + $inc, lastDownload = $last WHERE publishId = $publishId""".
      update

  def sqlUpdateFileDownloadStats(uploadId: String, fileId: String, inc: Int, last: Instant) =
    sql"""UPDATE UploadFile SET downloads = downloads + $inc, lastDownload = $last WHERE fileId = $fileId AND uploadId = $uploadId""".
      update

  def sqlSelectFileIds(uploadId: String) =
    sql"""SELECT fileId FROM UploadFile WHERE uploadId = $uploadId""".
      query[String].
      list

  def sqlDeleteFileChunks(ids: NonEmptyList[String]) =
    (sql"""DELETE FROM FileChunk WHERE """ ++ Fragments.in(fr"fileId", ids)).update

  def sqlDeleteFileMeta(ids: NonEmptyList[String]) =
    (sql"""DELETE FROM FileMeta WHERE """ ++ Fragments.in(fr"id", ids)).update

  def sqlDeleteUploadFile(id: String) =
    sql"""DELETE FROM UploadFile WHERE uploadId = $id""".
      update

  def sqlDeleteUpload(id: String, fileIds: List[String]) =
    NonEmptyList.fromList(fileIds) match {
      case Some(ids) =>
        for {
          _ <- sqlDeleteUploadFile(id).run
          _ <- sql"""DELETE FROM Upload WHERE id = $id""".update.run
          n <- sqlDeleteFileMeta(ids).run
          _ <- sqlDeleteFileChunks(ids).run
        } yield n

      case None =>
        for {
          _ <- sql"""DELETE FROM Upload WHERE id = $id""".update.run
          _ <- sqlDeleteUploadFile(id).run
        } yield 0

    }


  def sqlListInvalidSince(since: Instant) =
    sql"""SELECT id,publishUntil FROM Upload WHERE publishUntil < $since""".
      query[(String, Instant)].
      process

  def sqlInsertAlias(alias: Alias) =
    sql"""INSERT INTO Alias VALUES (${alias.id}, ${alias.login}, ${alias.name}, ${alias.validity}, ${alias.created}, ${alias.enable})""".
      update

  def sqlListAliases(login: String) =
    sql"""SELECT id,login,name,validity,created,enable
          FROM Alias WHERE login = $login
          ORDER BY created DESC""".
      query[Alias].
      process

  def sqlGetAlias(id: String) =
    sql"""SELECT id,login,name,validity,created,enable
          FROM Alias WHERE id = $id""".
      query[Alias].
      option

  def sqlDeleteAlias(id: String, login: String) =
    sql"""DELETE FROM Alias WHERE id = $id AND login = $login""".update

  def sqlUpdateAlias(a: Alias) =
    sql"""UPDATE Alias SET name = ${a.name}, validity = ${a.validity}, enable = ${a.enable}
          WHERE id = ${a.id} AND login = ${a.login}""".update

  def sqlGetActiveAlias(id: String) =
    sql"""SELECT al.id,al.login,al.name,al.validity,al.created,al.enable
          FROM Alias AS al
          INNER JOIN Account AS ac ON al.login = ac.login
          WHERE al.id = $id AND al.enable AND ac.enabled""".
      query[Alias].
      option

  def sqlGetUploadSize(id: String) =
    sql"""SELECT count(*), COALESCE(sum(length), 0)
          FROM UploadFile AS uf
          INNER JOIN FileMeta AS fm ON uf.fileid = fm.id
          WHERE uf.uploadid = $id""".
      query[UploadSize].
      unique

  def sqlGetUploadSizeFromChunks(id: String) =
    sql"""SELECT count(distinct fm.id), COALESCE(sum(length(fc.chunkdata)), 0)
          FROM UploadFile AS uf
          INNER JOIN FileMeta AS fm ON uf.fileid = fm.id
          INNER JOIN FileChunk AS fc ON fc.fileid = fm.id
          WHERE uf.uploadid = $id""".
      query[UploadSize].
      unique

}
