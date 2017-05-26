package sharry.server.routes

import java.time.{Duration, Instant}
import fs2.{Stream, Task}
import shapeless.{::,HNil}
import scodec.bits.ByteVector
import spinoco.fs2.http.routing._
import com.github.t3hnar.bcrypt._

import sharry.store.data._
import sharry.common.sizes._
import sharry.common.mime._
import sharry.common.streams
import sharry.common.sha
import sharry.store.mimedetect
import sharry.store.mimedetect.MimeInfo
import sharry.store.upload.UploadStore
import sharry.server.paths
import sharry.server.config._
import sharry.server.jsoncodec._
import sharry.server.notification
import sharry.server.notification.Notifier
import sharry.server.routes.syntax._

object upload {
  private implicit val logger = com.typesafe.scalalogging.Logger(getClass)

  def endpoint(auth: AuthConfig, uploadCfg: UploadConfig, store: UploadStore, notifier: Notifier) =
    choice(testUploadChunk(auth, store)
      , createUpload(auth, uploadCfg, store)
      , uploadChunks(auth, store)
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
        if (maxValidity.compareTo(given) >= 0) Right(given)
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
          map(Ok.body(_)).
          through(NotFound.whenEmpty)
    }

  def getPublishedUpload(store: UploadStore): Route[Task] =
    Get >> paths.uploadPublish.matcher / uploadId map { id =>
      store.getPublishedUpload(id).
        map(Ok.body(_)).
        through(NotFound.whenEmpty)
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
          notifier(id, alias, cfg.aliasDeleteTime.plusSeconds(30)).drain ++
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

  def uploadChunks(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Post >> paths.uploadData.matcher >> authz.userId(authCfg, store) :: chunkInfo :: body[Task].bytes map {
      case user :: info :: bytes :: HNil  =>
        val fileId = makeFileId(info)
        // create FileMeta and UploadFile on chunkNr=1
        val init = info.chunkNumber match {
          case 1 =>
            val fm = FileMeta(fileId, Instant.now, MimeType.unknown, info.totalSize.bytes, info.totalChunks, info.chunkSize.bytes)
            store.createUploadFile(info.token, fm, info.filename)
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
            store.addChunk(chunk) ++ mimeUpdate(chunk.chunkData)
          })

        val updateTimestamp =
          if (info.chunkNumber == info.totalChunks)
            store.updateTimestamp(info.token, fileId, Instant.now)
          else
            Stream.empty

        init.drain ++ chunk.drain ++ updateTimestamp.drain ++ Stream.emit(Ok.noBody)
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

  case class ChunkInfo(
    token: String
      , chunkNumber: Int
      , chunkSize: Int
      , currentChunkSize: Int
      , totalSize: Long
      , fileIdentifier: String
      , filename: String
      , totalChunks: Int
  )
}
