package sharry.server.routes

import java.time.{Duration, Instant}
import fs2.{Stream, Task}
import shapeless.{::,HNil}
import scodec.bits.ByteVector
import spinoco.protocol.http.HttpStatusCode
import spinoco.fs2.http.routing._
import com.github.t3hnar.bcrypt._

import sharry.store.data._
import sharry.store.data.sizes._
import sharry.store.data.mime._
import sharry.store.mimedetect
import sharry.store.mimedetect.MimeInfo
import sharry.store.data.streams
import sharry.server.paths
import sharry.server.config._
import sharry.server.jsoncodec._
import sharry.store.upload.UploadStore
import sharry.server.routes.syntax._

object upload {
  private val logger = com.typesafe.scalalogging.Logger(getClass)

  def endpoint(auth: AuthConfig, store: UploadStore) =
    choice(testUploadChunk(auth, store)
      , createUpload(auth, store)
      , uploadChunks(auth, store)
      , publishUpload(auth, store)
      , getPublishedUpload(store)
      , getUpload(auth, store)
      , getAllUploads(auth, store)
      , deleteUpload(auth, store))

  def createUpload(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Post >> paths.uploads.matcher >> authz.userId(authCfg, store) :: jsonBody[UploadCreate] map {
      case account :: meta :: HNil  =>
        parseValidity(meta, account.alias) match {
          case Right(v) =>
            if (meta.id.isEmpty) Stream.emit(BadRequest("The upload id must not be empty!"))
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
              store.createUpload(uc).map(_ => Ok(List[String]()))
            }
          case Left(msg) =>
            Stream.emit(BadRequest(msg))
        }
    }

  private def parseValidity(meta: UploadCreate, alias: Option[Alias]): Either[String, Duration] =
    alias.
      map(a => if (a.enable) Right(a.validity) else Left("Alias is disabled")).
      getOrElse(UploadCreate.parseValidity(meta.validity))


  def deleteUpload(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Delete >> paths.uploads.matcher / uploadId :: authz.userId(authCfg, store) map {
      case id :: user :: HNil =>
        if (id.isEmpty) Stream.emit(BadRequest("id is empty"))
        else store.deleteUpload(id, user.login).
          map(n => Ok[Task,Map[String,Int]](Map("filesRemoved" -> n))).
          through(NotFound.whenEmpty)
    }

  def getAllUploads(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Get >> paths.uploads.matcher >> authz.user(authCfg) map { user =>
      // add paging or cope with chunk responses in elm
      Stream.eval(store.listUploads(user).runLog).
        map(Ok[Task,Vector[Upload]](_))
    }

  def getUpload(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Get >> paths.uploads.matcher / uploadId :: authz.user(authCfg) map {
      case id :: user :: HNil =>
        store.getUpload(id, user).
          map(Ok[Task,UploadInfo](_)).
          through(NotFound.whenEmpty)
    }

  def getPublishedUpload(store: UploadStore): Route[Task] =
    Get >> paths.uploadPublish.matcher / uploadId map { id =>
      store.getPublishedUpload(id).
        map(Ok[Task,UploadInfo](_)).
        through(NotFound.whenEmpty)
    }


  def publishUpload(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Post >> paths.uploadPublish.matcher / uploadId :: authz.user(authCfg) map {
      case id :: user :: HNil =>
        store.publishUpload(id, user).flatMap {
          case Right(pid) => store.getPublishedUpload(pid).map(Ok[Task,UploadInfo](_))
          case Left(msg) => Stream.emit(BadRequest(Map("error" -> msg)))
        }
    }

  def testUploadChunk(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Get >> paths.uploadData.matcher >> authz.userId(authCfg, store) >> chunkInfo map { (info: ChunkInfo) =>
      val fileId = makeFileId(info)
      store.chunkExists(info.token, fileId, info.chunkNumber, info.currentChunkSize.bytes).map {
        case true =>
          Ok()
        case false =>
          emptyResponse(HttpStatusCode.NoContent)
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

        init.drain ++ chunk.drain ++ Stream.emit(Ok())
    }


  private def uploadId: Matcher[Task, String] =
    as[String].flatMap { s =>
      if (s.isEmpty) Matcher.respond(BadRequest("The upload token must not be empty!"))
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
        if (token.isEmpty) Matcher.respond[Task](BadRequest("Token is empty"))
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
