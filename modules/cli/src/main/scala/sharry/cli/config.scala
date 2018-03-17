package sharry.cli

import spinoco.protocol.http.Uri
import java.nio.file.{Path, Paths, Files}
import com.typesafe.config.{ConfigValueFactory, ConfigFactory}

import cats.syntax.either._
import fs2.Task
import pureconfig._
import pureconfig.ConvertHelpers._
import pureconfig.error._
import org.log4s._
import io.circe._, io.circe.generic.semiauto._

import sharry.common.JsonCodec
import sharry.common.duration._

object config {
  private val logger = getLogger

  case class Config(
    mode: Mode,
    endpoint: Uri,
    auth: AuthMethod,
    valid: Duration,
    maxDownloads: Int,
    resumeFile: Path,
    source: Option[Path] = None,
    password: Option[String] = None,
    parallelUploads: Option[Int] = None,
    description: Option[String] = None,
    descriptionFile: Option[Path] = None,
    loglevel: String = "off",
    files: Seq[Path] = Seq.empty
  )

  sealed trait Mode extends Product {
    lazy val name: String = KebabCase.fromTokens(CamelCase.toTokens(productPrefix))
  }
  object Mode {
    case object UploadFiles extends Mode
    case object PublishFiles extends Mode
    case object MdUpload extends Mode
    case object MdPublish extends Mode
    case class Resume(abort: Boolean) extends Mode
    case class Manual(html: Boolean) extends Mode

    implicit val jsonEncoder: Encoder[Mode] = deriveEncoder[Mode]
    implicit val jsonDecoder: Decoder[Mode] = deriveDecoder[Mode]
  }

  sealed trait AuthMethod
  object AuthMethod {
    case class AliasHeader(alias: String) extends AuthMethod
    case class UserLogin(login: String, password: String, passwordCommand: String) extends AuthMethod {
      def readPassword: Task[String] =
        if (passwordCommand.trim.isEmpty) Task.now(password)
        else OS.command(passwordCommand).
          flatMap(_.runFirstLine)
    }
    case object NoAuth extends AuthMethod

    implicit val jsonDecoder: Decoder[AuthMethod] = deriveDecoder[AuthMethod]
    implicit val jsonEncoder: Encoder[AuthMethod] = deriveEncoder[AuthMethod]
  }

  object Config {
    val empty = Config(Mode.PublishFiles, Uri.http("localhost", ""), AuthMethod.NoAuth, Duration.zero, 0, Paths.get(""))

    private def readValue[A](s: String)(implicit r: ConfigReader[A]): Either[ConfigReaderFailures, A] =
      r.from(ConfigValueFactory.fromAnyRef(s))

    private def throwLeft[A](e: Either[ConfigReaderFailures, A]): A =
      e.valueOr(x => throw new ConfigReaderException(x))

    def readDuration(s: String): Either[ConfigReaderFailures, Duration] =
      readValue[Duration](s)

    def readDurationOrThrow(s: String) =
      throwLeft(readDuration(s))

    def readPath(s: String): Either[ConfigReaderFailures, Path] =
      readValue[Path](s)

    def readExistingPathOrThrow(s: String) = {
      val reason = Some(new Exception(s"The file '$s' cannot be found"))
      throwLeft(readPath(s).ensure(ConfigReaderFailures(CannotReadFile(Paths.get(s), reason)))(f => Files.exists(f)))
    }

    def readUri(s: String): Either[ConfigReaderFailures, Uri] =
      readValue[Uri](s)

    def readUriOrThrow(s: String): Uri =
      throwLeft(readUri(s))

    val defaultConfig: Either[ConfigReaderFailures, Config] =
      loadConfig[Config]("sharry.cli")

    def fromFile(file: String): Either[ConfigReaderFailures, Config] =
      readPath(file).flatMap(fromPath)

    def fromPath(file: Path): Either[ConfigReaderFailures, Config] =
      loadConfig[Config](file, "sharry.cli")

    def fromDefaultConfig(source: Option[Path]): Either[ConfigReaderFailures, Config] = {
      val userdir = readPath(ConfigFactory.defaultReference().getString("user.home"))
      val file = Right(source).
        flatMap {
          case Some(f) => Right(f)
          case None =>
            userdir.map(d => d.resolve(".config").resolve("sharry").resolve("cli.conf"))
        }
      file.flatMap { f =>
        if (!Files.exists(f)) {
          logger.debug(s"Configuration file $f doesn't exist.")
          defaultConfig
        } else {
          logger.debug(s"Loading config from file $file")
          fromPath(f)
        }
      }
    }

    def loadDefaultConfig(source: Option[Path]): Task[Config] = Task.delay {
      fromDefaultConfig(source) match {
        case Right(c) => c
        case Left(errs) => throw new ConfigReaderException(errs)
      }
    }

    implicit def hint[T] = ProductHint[T](ConfigFieldMapping(CamelCase, KebabCase))

    implicit def uriConvert: ConfigReader[Uri] = ConfigReader.fromString[Uri](catchReadError(s =>
      Uri.parse(s).toEither match {
        case Right(u) => u
        case Left(err) => throw new IllegalArgumentException(s"Uri parsing failed: $err")
      }
    ))

    implicit def pathConvert: ConfigReader[Path] = ConfigReader.fromString[Path](catchReadError(s =>
      Paths.get(s)
    ))

    implicit def durationConvert: ConfigReader[Duration] = ConfigReader.fromString[Duration](catchReadError(s =>
      Duration.unsafeParse(s)
    ))

    implicit def modeConvert: ConfigReader[Mode] =
      ConfigReader.fromString[Mode](s => s match {
        case Mode.UploadFiles.name => Right(Mode.UploadFiles)
        case Mode.PublishFiles.name => Right(Mode.PublishFiles)
        case Mode.MdUpload.name => Right(Mode.MdUpload)
        case Mode.MdPublish.name => Right(Mode.MdPublish)
        case s => Right(Mode.PublishFiles)
      })


    import JsonCodec._

    implicit val _uriDec: Decoder[Uri] = Decoder.decodeString.map(s => Uri.parse(s).require)
    implicit val _uriEnc: Encoder[Uri] = Encoder.encodeString.contramap(uri => uri.asString)

    implicit val jsonDecoder: Decoder[Config] = deriveDecoder[Config]
    implicit val jsonEncoder: Encoder[Config] = deriveEncoder[Config]

  }
}
