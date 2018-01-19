package sharry.cli

import cats.implicits._
import cats.data.{Validated, ValidatedNel}
import fs2.{text, Chunk, Stream, Task}
import fs2.io.file
import fs2.async.mutable.Signal
import sharry.cli.config._
import sharry.common.data._
import sharry.common.file._
import sharry.common.sizes._
import sharry.common.rng._
import sharry.common.duration._
import spinoco.fs2.http.HttpRequest
import spinoco.fs2.http.body.StreamBodyEncoder
import spinoco.protocol.http._
import spinoco.protocol.http.header.{Cookie, GenericHeader,`Content-Length`}
import spinoco.protocol.http.header.value.HttpCookie
import io.circe._, io.circe.generic.semiauto._

case class Context(
  config: Config
    , remoteConfig: RemoteConfig
    , cookie: Option[Signal[Task,HttpCookie]] = None
    , upload: Upload = Upload.empty
) {

  def parallelUploads: Int =
    config.parallelUploads.map(n => math.min(n, remoteConfig.simultaneousUploads)).
      getOrElse(remoteConfig.simultaneousUploads)

  lazy val size = config.files.foldLeft(0L)(_ + _.length).bytes
  lazy val count = config.files.size

  def uri(key: String): Uri = {
    config.endpoint / Uri.Path.fromUtf8String(remoteConfig.urls(key))
  }

  def serverSettingReq: HttpRequest[Task] =
    HttpRequest.get(config.endpoint/"api"/"v1"/"settings")

  def loginReq(up: UserPass): HttpRequest[Task] =
    HttpRequest.post(uri("authLogin"), up)

  def loginRefreshReq(cookie: HttpCookie): HttpRequest[Task] =
    HttpRequest.post(uri("authCookie"), "").
      appendHeader(Cookie(cookie))


  def readSingleFile: Stream[Task, String] =
    file.readAll[Task](config.files.head, 8192).
      through(text.utf8Decode).
      fold1(_ + _)

  def newUpload: Stream[Task, UploadCreate] = {
    val descr = config.descriptionFile match {
      case Some(f) =>
        file.readAll[Task](f, 8192).
          through(text.utf8Decode).
          fold1(_ + _)
      case None =>
        Stream(config.description.getOrElse(""))
    }
    descr.map { d =>
      UploadCreate(
        id = "c"+ Gen.ident(16, 32).generate()
          , description = d
          , validity = config.valid.formatExact
          , maxdownloads = config.maxDownloads
          , password = config.password.getOrElse(""))
    }
  }

  def createUploadReq(up: UploadCreate): Stream[Task, HttpRequest[Task]] =
    authRequest(HttpRequest.post(uri("uploads"), up))

  def getUploadReq(id: String): Stream[Task, HttpRequest[Task]] =
    authRequest(HttpRequest.get(uri("uploads")/id))

  def deleteUploadReq(id: String): Stream[Task, HttpRequest[Task]] = {
    authRequest(HttpRequest.delete(uri("uploads") / id))
  }

  def publishUploadReq: Stream[Task, HttpRequest[Task]] = {
    authRequest(HttpRequest.post(uri("uploadPublish") / upload.id, ""))
  }

  def checkChunkReq(info: ChunkInfo): Stream[Task, HttpRequest[Task]] =
    authRequest(HttpRequest.get(uri("uploadData")).
      withQuery(queryParams(info)))

  def uploadChunkReq(info: ChunkInfo, data: Chunk[Byte]): Stream[Task, HttpRequest[Task]] =
    authRequest(HttpRequest.get(uri("uploadData")).
      withMethod(HttpMethod.POST).
      appendHeader(`Content-Length`(info.currentChunkSize.toLong)).
      withQuery(queryParams(info)).
      withStreamBody(Stream.chunk(data))(StreamBodyEncoder.byteEncoder))

  private def queryParams(info: ChunkInfo): Uri.Query =
    Uri.Query.empty :+ ("token", info.token) :+
      ("resumableChunkNumber", info.chunkNumber.toString) :+
      ("resumableChunkSize", info.chunkSize.toString) :+
      ("resumableCurrentChunkSize", info.currentChunkSize.toString) :+
      ("resumableTotalSize", info.totalSize.toString) :+
      ("resumableIdentifier", info.fileIdentifier) :+
      ("resumableFilename", info.filename) :+
      ("resumableTotalChunks", info.totalChunks.toString)

  private def authRequest(req: HttpRequest[Task]): Stream[Task, HttpRequest[Task]] =
    config.auth match {
      case AuthMethod.AliasHeader(alias) =>
        Stream(req.appendHeader(GenericHeader(remoteConfig.aliasHeaderName, alias)))
      case AuthMethod.UserLogin(_, _, _) =>
        cookie match {
          case Some(s) =>
            Stream.eval(s.get).map { c =>
              req.appendHeader(Cookie(c))
            }
          case None =>
            Stream.fail(ClientError("No cookie to authenticate"))
        }
      case AuthMethod.NoAuth =>
        Stream(req)
    }

}

object Context {
  private def successWhen(cond: Boolean, err: => String): ValidatedNel[String, Unit] =
    if (cond) Validated.valid(())
    else Validated.invalidNel(err)

  def validate(ctx: Context): ValidatedNel[String, Context] = {
    val v1 = successWhen(
      ctx.size <= ctx.remoteConfig.maxFileSize.bytes,
      s"Size of upload (${ctx.size.asString}) exceeds server limit (${ctx.remoteConfig.maxFileSize.bytes.asString}).")

    val v2 = successWhen(
      ctx.count <= ctx.remoteConfig.maxFiles,
      s"Number of files (${ctx.count}) exceeds server limit (${ctx.remoteConfig.maxFiles}).")

    val v3 = Duration.parse(ctx.remoteConfig.maxValidity).toValidatedNel[String,Duration].andThen(maxValidity =>
      successWhen(
        !(maxValidity - ctx.config.valid).isNegative,
        s"Validity (${ctx.config.valid}) exceeds server limit (${ctx.remoteConfig.maxValidity})."))

    val v4 = successWhen(
      ctx.count > 0 || ctx.config.description.isDefined || ctx.config.descriptionFile.isDefined,
      "You must at least specify some files to upload or a description.")

    (v1 |+| v2 |+| v3 |+| v4).map { _ =>
      ctx.copy(config = ctx.config.copy(parallelUploads =
        ctx.config.parallelUploads.map(n =>
          math.min(n, ctx.remoteConfig.simultaneousUploads)).
          orElse(Some(ctx.remoteConfig.simultaneousUploads))))
    }
  }

  implicit val _signalDecoder: Decoder[Option[Signal[Task,HttpCookie]]] = Decoder.decodeString.map(_ => None)
  implicit val _signalEncoder: Encoder[Option[Signal[Task,HttpCookie]]] = Encoder.encodeString.contramap(_ => "")

  implicit val jsonDecoder: Decoder[Context] = deriveDecoder[Context]
  implicit val jsonEncoder: Encoder[Context] = deriveEncoder[Context]

}
