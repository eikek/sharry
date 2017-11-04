package sharry.server.routes

import java.time.Instant
import fs2.{Stream, Task}
import shapeless.{::,HNil}
import scala.util.Try
import scodec.bits.ByteVector
import spinoco.fs2.http.routing._
import com.github.t3hnar.bcrypt._
import org.log4s._

import sharry.store.data._
import sharry.common.data._
import sharry.common.sizes._
import sharry.common.mime._
import sharry.common.duration._
import sharry.common.streams
import sharry.common.sha
import sharry.store.mimedetect
import sharry.store.mimedetect.MimeInfo
import sharry.store.upload.UploadStore
import sharry.server.paths
import sharry.server.config._
import sharry.server.notification
import sharry.server.notification.Notifier
import sharry.server.routes.syntax._

object upload {
  private implicit val logger = getLogger

  def endpoint(auth: AuthConfig, uploadCfg: UploadConfig, store: UploadStore, notifier: Notifier) =
    choice2(testUploadChunk(auth, store)
      , createUpload(auth, uploadCfg, store)
      , uploadChunks(auth, uploadCfg, store)
      , publishUpload(auth, store)
      , unpublishUpload(auth, store)
      , getPublishedUpload(store)
      , getUpload(auth, store)
      , getAllUploads(auth, store)
      , deleteUpload(auth, uploadCfg, store)
      , notifyOnUpload(uploadCfg, store, notifier))

  def createUpload(authCfg: AuthConfig, cfg: UploadConfig, store: UploadStore): Route[Task] =
    Post >> paths.uploads.matcher >> authz.userId(authCfg, store) :: jsonBody[UploadCreate] map {
      case account :: meta :: HNil  =>
        checkValidity(meta, account.alias, cfg.maxValidity) match {
          case Right(v) =>
            if (meta.id.isEmpty) Stream.emit(BadRequest.message("The upload id must not be empty!"))
            else {
              val uc = Upload(
                id = meta.id,
                login = account.login,
                validity = v,
                maxDownloads = meta.maxdownloads,
                description = meta.description.asNonEmpty,
                password = meta.password.asNonEmpty.map(_.bcrypt),
                alias = account.aliasId
              )
              store.createUpload(uc).map(_ => Ok.message("Upload created"))
            }
          case Left(msg) =>
            Stream.emit(BadRequest.message(msg))
        }
    }

  private def checkValidity(meta: UploadCreate, alias: Option[Alias], maxValidity: Duration): Either[String, Duration] =
    alias.
      map(a => Right(a.validity)).
      getOrElse(UploadCreate.parseValidity(meta.validity)).
      flatMap { given =>
        if (maxValidity >= given) Right(given)
        else Left("Validity time is too long.")
      }


  private def checkDelete(id: String, alias: Alias, time: Duration, store: UploadStore) = {
    notification.checkAliasAccess(id, alias, time, store)
  }

  private def doDeleteUpload(store: UploadStore, id: String, login: String) =
    store.deleteUpload(id, login).
      map(n => Ok.body(Map("filesRemoved" -> n))).
      through(NotFound.whenEmpty)

  def deleteUpload(authCfg: AuthConfig, uploadCfg: UploadConfig, store: UploadStore): Route[Task] =
    Delete >> paths.uploads.matcher / uploadId :: authz.userId(authCfg, store) map {
      case id :: user :: HNil =>
        if (id.isEmpty) Stream.emit(BadRequest.message("id is empty"))
        else user match {
          case Username(login) => doDeleteUpload(store, id, login)
          case AliasId(alias) =>
            checkDelete(id, alias, uploadCfg.aliasDeleteTime, store).
              flatMap{
                case true =>
                  logger.info(s"Delete upload $id as requested by alias $alias")
                  doDeleteUpload(store, id, alias.login)
                case false =>
                  logger.info(s"Not deleting upload $id as requested by alias $alias")
                  Stream.emit(Forbidden.message("Not authorized for deletion."))
              }
        }
    }

  def getAllUploads(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Get >> paths.uploads.matcher >> authz.user(authCfg) map { user =>
      // add paging or cope with chunk responses in elm
      Stream.eval(store.listUploads(user).runLog).
        map(Ok.body(_))
    }

  def getUpload(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Get >> paths.uploads.matcher / uploadId :: authz.user(authCfg) map {
      case id :: user :: HNil =>
        store.getUpload(id, user).
          map(processDescription(paths.download)).
          map(Ok.body(_)).
          through(NotFound.whenEmpty)
    }

  def getPublishedUpload(store: UploadStore): Route[Task] =
    Get >> paths.uploadPublish.matcher / uploadId map { id =>
      store.getPublishedUpload(id).
        map(processDescription(paths.downloadPublished)).
        map(Ok.body(_)).
        through(NotFound.whenEmpty)
    }

  private def processDescription(baseUrl: paths.Path)(u: UploadInfo): UploadInfo = {
    import yamusca.imports._, yamusca.implicits._

    implicit val fileConverter: ValueConverter[UploadInfo.File] = f => Map(
      "id" -> f.clientFileId,
      "filename" -> f.filename,
      "url" -> (baseUrl / f.meta.id).path,
      "mimetype" -> f.meta.mimetype.asString,
      "size" -> f.meta.length.asString
    ).asMustacheValue

    val ctx = Context.from { key => key match {
      case "id" => u.upload.publishId.map(Value.of)
      case "files" => Some(u.files.asMustacheValue)
      case name if name startsWith "file_" =>
        Try(name.drop(5).toInt).toOption match {
          case Some(i) if i < u.files.size =>
            Some(u.files(i).asMustacheValue)
          case _ =>
            None
        }
      case name if name startsWith "fileid_" =>
        Try(name.drop(7)).
          toOption.
          filter(_.trim.nonEmpty).
          flatMap(id => u.files.find(_.clientFileId == id)).
          map(_.asMustacheValue)
      case _ => None
    }}

    val desc = u.upload.description.map(mustache.parse) match {
      case Some(Right(t)) => Some(mustache.render(t)(ctx))
      case Some(Left(err)) => u.upload.description
      case None => None
    }

    u.copy(upload = u.upload.copy(description = desc))
  }

  def publishUpload(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Post >> paths.uploadPublish.matcher / uploadId :: authz.user(authCfg) map {
      case id :: user :: HNil =>
        store.publishUpload(id, user).flatMap {
          case Right(pid) => store.getPublishedUpload(pid).map(Ok.body(_))
          case Left(msg) => Stream.emit(BadRequest.message(msg))
        }
    }

  def unpublishUpload(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Post >> paths.uploadUnpublish.matcher / uploadId :: authz.user(authCfg) map {
      case id :: login :: HNil =>
        store.unpublishUpload(id, login).flatMap {
          case Right(_) => store.getUpload(id, login).map(Ok.body(_))
          case Left(msg) => Stream.emit(BadRequest.message(msg))
        }
    }

  def notifyOnUpload(cfg: UploadConfig, store: UploadStore, notifier: Notifier): Route[Task] =
    Post >> paths.uploadNotify.matcher / uploadId :: authz.alias(store) map {
      case id :: alias :: HNil =>
        if (cfg.enableUploadNotification) {
          notifier(id, alias, cfg.aliasDeleteTime + 30.seconds).drain ++
          Stream.emit(Ok.message("Notification scheduled."))
        } else {
          Stream.emit(Ok.message("Upload notifications disabled."))
        }
    }

  def testUploadChunk(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Get >> paths.uploadData.matcher >> authz.userId(authCfg, store) >> chunkInfo map { (info: ChunkInfo) =>
      val fileId = makeFileId(info)
      store.chunkExists(info.token, fileId, info.chunkNumber, info.currentChunkSize.bytes).map {
        case true =>
          Ok.noBody
        case false =>
          NoContent.noBody
      }
    }

  def uploadChunks(authCfg: AuthConfig, cfg: UploadConfig, store: UploadStore): Route[Task] =
    Post >> paths.uploadData.matcher >> authz.userId(authCfg, store) :: chunkInfo :: body[Task].bytes map {
      case user :: info :: bytes :: HNil  =>
        val fileId = makeFileId(info)
        // create FileMeta and UploadFile on chunkNr=1
        val init = info.chunkNumber match {
          case 1 =>
            val fm = FileMeta(fileId, Instant.now, MimeType.unknown, info.totalSize.bytes, info.totalChunks, info.chunkSize.bytes)
            store.createUploadFile(info.token, fm, info.filename, info.fileIdentifier)
          case _ => Stream.empty
        }

        def mimeUpdate(bytes: ByteVector) =
          info.chunkNumber match {
            case 1 =>
              val mime = mimedetect.fromBytes(bytes, MimeInfo.file(info.filename))
              logger.debug(s"Start upload of ${info.filename} (${info.totalSize.bytes.asString}, ${mime.asString}) for $user")
              store.updateMime(fileId, mime)
            case _ =>
              Stream.empty
          }

        val chunk = bytes.take(info.currentChunkSize.toLong).
          through(streams.append).
          map(data => FileChunk(fileId, info.chunkNumber, data)).
          flatMap(chunk => {
            store.addChunk(info.token, chunk) ++ mimeUpdate(chunk.chunkData)
          })

        val updateTimestamp =
          if (info.chunkNumber == info.totalChunks)
            store.updateTimestamp(info.token, fileId, Instant.now)
          else
            Stream.empty

        val sizeCheck = store.getUploadSize(info.token).
          map({ case us@UploadSize(n, len) =>
            (us, n <= cfg.maxFiles && (len + info.currentChunkSize.bytes) <= cfg.maxFileSize)
          }).
          evalMap({ case (UploadSize(n, len), result) => Task.delay {
            if (!result) {
              logger.info(s"Current upload chunk (${info.currentChunkSize.bytes.asString}) exceeds max size: size=${len + info.currentChunkSize.bytes} and count=$n")
            }
            result
          }}).
          through(streams.ifEmpty(Stream.emit(true)))

        sizeCheck.flatMap {
          case true =>
            init.drain ++ chunk.drain ++ updateTimestamp.drain ++ Stream.emit(Ok.noBody)
          case false =>
            logger.info("Uploading too many or too large files. Return with error.")
            // http 404,415,500,501 tells resumable.js to cancel entire upload (other codes let it retry)
            Stream.emit(NotFound.message("Size limit exceeded"))
        }
    }


  private def uploadId: Matcher[Task, String] =
    as[String].flatMap { s =>
      if (s.isEmpty) Matcher.respond(BadRequest.message("The upload token must not be empty!"))
      else Matcher.success(s)
    }

  private def makeFileId(info: ChunkInfo): String =
    sha(info.token + info.fileIdentifier)

  private def chunkInfo: Matcher[Task, ChunkInfo] =
    param[String]("token") :: param[Int]("resumableChunkNumber") ::
    param[Int]("resumableChunkSize") :: param[Int]("resumableCurrentChunkSize") ::
    param[Long]("resumableTotalSize") :: param[String]("resumableIdentifier") ::
    param[String]("resumableFilename") :: param[Int]("resumableTotalChunks") flatMap {
      case token :: num :: size :: currentSize :: totalSize :: ident :: file :: total :: HNil =>
        if (token.isEmpty) Matcher.respond[Task](BadRequest.message("Token is empty"))
        else Matcher.success(ChunkInfo(token, num, size, currentSize, totalSize, ident, file, total))
  }
}
