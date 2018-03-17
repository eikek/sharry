package sharry.cli

import java.nio.file.Path

import fs2.{async, text, Pipe, Scheduler, Stream}
import cats.effect.IO
import fs2.io.file
import fs2.async.mutable.Signal
import spinoco.fs2.http.HttpClient
import spinoco.protocol.http.header.`Set-Cookie`
import spinoco.protocol.http.header.value.HttpCookie
import spinoco.protocol.http.HttpStatusCode
import io.circe.parser._
import org.log4s._
import yamusca.implicits._
import scala.concurrent.ExecutionContext

import sharry.common.data._
import sharry.common.file._
import sharry.common.sizes._
import sharry.common.duration._
import sharry.cli.config._
import sharry.mdutil.{Document,Link}

object cmds extends requestlog {
  import Cmd.syntax._

  val logger = getLogger

  def sendPrepare: Cmd = Cmd { (_, progress) => ctx =>
    progress.info(Progress.Prepare(ctx.config)) ++ Stream(ctx)
  }

  def checkResumeFile: Cmd = Cmd { (_, _) => ctx =>
    val msg = "There is an uncompleted upload. Either use `resume --abort' to remove it or run `resume --continue' to resume the upload."
    logger.debug(s"Checking non-existence of resume file: ${ctx.config.resumeFile}")
    if (ctx.config.resumeFile.exists) Stream.raiseError(ClientError(msg))
    else Stream(ctx)
  }

  def writeResumeFile: Cmd = Cmd { (_, _) => ctx =>
    Stream.eval(
      ctx.config.resumeFile.parent.mkdirs().map { _ =>
        logger.debug(s"Writing to resume file: $ctx")
        ctx.config.resumeFile.write(ctx)
      }).map(_ => ctx)
  }

  def deleteResumeFile: Cmd = Cmd { (_, _) => ctx =>
    logger.debug(s"Deleting resume file: ${ctx.config.resumeFile}")
    Stream.eval(ctx.config.resumeFile.delete).map(_ => ctx)
  }

  def loadResumeFile: Cmd = Cmd { (_, _) => ctx =>
    logger.debug(s"Loading context from resume file: ${ctx.config.resumeFile}")
    if (!ctx.config.resumeFile.exists) Stream.raiseError(ClientError("There is no upload to resume or abort."))
    else ctx.config.resumeFile.readAll(8192.bytes).
      through(text.utf8Decode).
      through(text.lines).
      fold1(_ + _).
      evalMap(str => IO(decode[Context](str))).
      flatMap {
        case Right(a) => Stream(a)
        case Left(err) => Stream.raiseError(ClientError(err.toString))
      }.
      map(fileCtx => ctx.copy(upload = fileCtx.upload).copy(config = fileCtx.config))
  }

  def loadServerSettings: Cmd = Cmd { (client, progress) => ctx =>
    logger.debug("Load server settings")
    val remoteConfig = for {
      resp <- client.dorequest(ctx.serverSettingReq)
      rcfg <- Stream.eval(resp.bodyAs[RemoteConfig])
    } yield rcfg.fold(err => throw ClientError(err.toString), rcfg => ctx.copy(remoteConfig = rcfg))
    remoteConfig.flatMap { c => progress.info(Progress.ServerWelcome(c)) ++ Stream(c) }
  }

  def validateContext: Cmd = Cmd { (_, _) => ctx =>
    logger.debug("Validating user input against server settings")
    Stream.eval(IO(Context.validate(ctx).fold(fail => throw ClientError(fail), identity)))
  }

  def checkVersions: Cmd = Cmd { (_, progress) => ctx =>
    logger.debug("Checking cli and server versions")
    val vm = Progress.VersionMismatch(ctx.remoteConfig.version)
    val check: Stream[IO, Nothing] = if (vm.isMismatch) progress.info(vm) else Stream.empty
    check ++ Stream(ctx)
  }

  def login: Cmd = new Cmd {
    def apply(client: HttpClient[IO], progress: Signal[IO, Progress])
      (implicit S: ExecutionContext, SCH: Scheduler): Pipe[IO, Context, Context] =
      _.flatMap { ctx =>
        ctx.config.auth match {
          case a@AuthMethod.UserLogin(login, _, _) =>
            logger.debug(s"Authenticating with user/password pair for $login")
            progress.info(Progress.Authenticating(ctx.config.endpoint)) ++ Stream.eval(a.readPassword).
              flatMap { pass =>
                client.dorequest(ctx.loginReq(UserPass(login, pass)))
                  .flatMap { resp =>
                    if (resp.header.status == HttpStatusCode.Ok) {
                      resp.header.firstHeader[`Set-Cookie`].
                        map(_.value).
                        map(c => Stream.eval(async.signalOf[IO, HttpCookie](c)).map(s => ctx.copy(cookie = Some(s)))).
                        getOrElse(Stream(ctx))
                    } else {
                      Stream.raiseError(ClientError("Authentication failed!"))
                    }
                  }
              }
          case _ =>
            logger.debug(s"No authentication necessary in auth-mode ${ctx.config.auth}")
            Stream(ctx)
        }
      }
  }

  def refreshCookie: Cmd = new Cmd {
    def apply(client: HttpClient[IO], progress: Signal[IO, Progress])
      (implicit S: ExecutionContext, SCH: Scheduler): Pipe[IO, Context, Context] =
      _.flatMap { ctx =>
        ctx.cookie match {
          case Some(s) =>
            val interval = math.max(2000, ctx.remoteConfig.cookieAge - 1000).millis.asScala
            val setter: Stream[IO, Unit] = for {
              _ <- SCH.awakeEvery[IO](interval)
              _ <- log(_.debug("Awake for refreshing cookie"))
              cookie <- Stream.eval(s.get)
              _ <- log(_.debug("Refreshing cookie now"))
              resp <- client.dorequest(ctx.loginRefreshReq(cookie))
              _ <- resp.header.firstHeader[`Set-Cookie`].
                     filter(_ => resp.header.status == HttpStatusCode.Ok).
                     map(nc => Stream.eval(s.set(nc.value))).
                     getOrElse(Stream.emit(()).covary[IO])
            } yield ()
            logger.debug(s"Scheduling cookie refresh every ${interval}")
            Stream.eval(async.start(setter.compile.drain)).drain ++ Stream(ctx)
          case None =>
            Stream(ctx)
        }
      }
  }

  def createUpload: Cmd = Cmd { (client, progress) => ctx =>
    progress.info(Progress.CreateUpload) ++ (for {
      up <- ctx.newUpload
      _ <- log(_.debug(s"Creating upload: $up"))
      req <- ctx.createUploadReq(up)
      resp <- client.dorequest(req).through(ClientError.onSuccess)
      upload <- Stream(Upload(up.id, "", Duration.zero, up.maxdownloads))
    } yield ctx.copy(upload = upload))
  }

  case class ChunkResult(path: Path, info: ChunkInfo, status: HttpStatusCode)
  type FileId = Path => String
  object FileId {
    def normalize(str: String): String =
      str.replaceAll("[\\s\\.]+", "-")

    def default: FileId = file =>
      s"${file.length}-${normalize(file.name)}"
  }

  def uploadFile(client: HttpClient[IO])(path: Path, progress: Signal[IO, Progress], fileId: FileId, ctx: Context): Stream[IO, ChunkResult] = {
    val chunkSize = ctx.remoteConfig.chunkSize.toInt
    val fileName = path.name
    val fileSize = path.length
    val totalChunks = fileSize / chunkSize + (if (fileSize % chunkSize == 0) 0 else 1)
    file.readAll[IO](path, chunkSize).
      chunks.
      zipWithIndex.
      flatMap { case (chunk, i) =>
        val info = ChunkInfo(ctx.upload.id, i.toInt+1, chunkSize, chunk.size, fileSize, fileId(path), fileName, totalChunks.toInt)
        val progressUpdate = progress.update {
          case Progress.Uploaded(current, total) =>
            Progress.Uploaded(current + info.currentChunkSize.bytes, total)
          case _ =>
            Progress.Uploaded(info.currentChunkSize.bytes, ctx.size)
        }
        ctx.checkChunkReq(info).flatMap(req => client.dorequest(req)).
          flatMap { checkResp =>
            if (checkResp.header.status == HttpStatusCode.Ok) {
              log(_.debug(s"Chunk $info already uploaded.")).drain ++
                Stream(ChunkResult(path, info, HttpStatusCode.Ok)) ++ progressUpdate
            } else {
              log(_.debug(s"Uploading chunk $info.")).drain ++ ctx.uploadChunkReq(info, chunk).
                flatMap(req => client.dorequest(req)).
                map(_.header.status).
                map(ChunkResult(path, info, _)) ++ progressUpdate
            }
          }
      }
  }

  def uploadAllFiles(fileId: FileId): Cmd = new Cmd {
    def apply(client: HttpClient[IO], progress: Signal[IO, Progress])
      (implicit S: ExecutionContext, SCH: Scheduler): Pipe[IO, Context, Context] =
      _.flatMap { ctx =>
        logger.info(s"Start uploading ${ctx.count} files")
        if (ctx.config.files.isEmpty) Stream(ctx)
        else {
          val all = Stream.emits(ctx.config.files).covary[IO].
            map(path => uploadFile(client)(path, progress, fileId, ctx))

          all.join(ctx.parallelUploads).
            fold1((a,b) => a). // TODO handle errors in chunks
            map(_ => ctx)
        }
      }
  }

  def deleteUpload: Cmd = Cmd { (client, progress) => ctx =>
    logger.info(s"Deleting upload: ${ctx.upload.id}")
    progress.info(Progress.DeleteUpload) ++ ctx.deleteUploadReq(ctx.upload.id).
      flatMap(req => client.dorequest(req)).
      through(ClientError.onSuccess).
      map(_ => ctx).
      handleErrorWith { ex =>
        progress.info(Progress.Error(ex)) ++ Stream(ctx)
      }
  }

  def publishUpload: Cmd = Cmd { (client, progress) => ctx =>
    ctx.config.auth match {
      case AuthMethod.AliasHeader(_) =>
        log(_.info("Not publishing an upload to an alias")).drain ++ Stream(ctx)
      case _ =>
        logger.debug(s"Publishing upload ${ctx.upload.id}")
        progress.info(Progress.PublishUpload) ++ ctx.publishUploadReq.
          flatMap(req => client.dorequest(req)).
          through(ClientError.onSuccess).
          flatMap(resp => Stream.eval(resp.bodyAs[UploadInfo].map(_.map(_.upload).require))).
          map(up => ctx.copy(upload = up))
    }
  }

  def processMarkdown(fileId: FileId): Cmd = Cmd { (_, progress) => ctx =>
    logger.debug(s"Processing markdown file: ${ctx.config.files.headOption}")
    progress.info(Progress.ProcessingMarkdown) ++ ctx.readSingleFile.
      evalMap(str => IO(Document.parse(str))).
      map { doc =>
        val files = collection.mutable.ListBuffer[Path]()
        val p = doc.mapLinks { link =>
          val f = sharry.common.file(link.path)
          if (f.exists) {
            files += f
            Link(s"{{fileid_${fileId(f)}.url}}")
          } else link
        }
        ctx.copy(config = ctx.config.copy(
          description = Some(p.renderMd)
            , descriptionFile = None
            , files = files.toList))
    }
  }

  def manual(html: Boolean): Cmd = Cmd { (_, progress) => ctx =>
    val reference = IO(scala.io.Source.fromURL(getClass.getResource("/reference.conf")).getLines.mkString("\n"))
    val helpStr = parser.optionParser.renderUsage(parser.optionParser.renderingMode)
    val md = IO(scala.io.Source.fromURL(getClass.getResource("/cli.md")).getLines.mkString("\n")).
      flatMap { str => reference.flatMap { ref =>
        IO(Map("cli-help" -> helpStr, "default-cli-config" -> ref).unsafeRender(str))
      }}
    val toHtml: String => IO[String] = mdText => IO {
      if (html) Document.parse(mdText).renderHtml else mdText
    }

    log(_.info("Preparing manual")).drain ++ Stream.eval(md).
      evalMap(toHtml).
      map(Progress.Manual(_, html)).
      flatMap(progress.info) ++ Stream(ctx)
  }
}
