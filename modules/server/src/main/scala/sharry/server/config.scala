package sharry.server

import java.nio.file.Path
import java.util.UUID
import scodec.bits.ByteVector
import cats.effect.IO
import doobie.hikari._
import pureconfig._
import pureconfig.error._
import pureconfig.ConvertHelpers._
import spinoco.protocol.http.Uri
import yamusca.imports._
import sharry.common.sizes._
import sharry.common.file._
import sharry.common.duration._
import sharry.server.email._

object config {

  case class Jdbc(driver: String, url: String, user: String, password: String) {
    def transactor: IO[HikariTransactor[IO]] =
      HikariTransactor.newHikariTransactor[IO](driver, url, user, password)
  }

  case class AuthConfig(enable: Boolean, defaultUser: String, maxCookieLifetime: Duration, appKey: ByteVector)

  case class AuthcCommand(enable: Boolean, program: Seq[String], success: Int)

  case class AuthcHttp(enable: Boolean, url: String, method: String, body: String, contentType: String)

  case class AdminAccount(enable: Boolean, login: String, password: String)

  case class WebConfig(bindHost: String
    , bindPort: Int
    , appName: String
    , baseurl: String
    , highlightjsTheme: String
    , welcomeMessage: String) {
    lazy val domain = Uri.parse(baseurl).require.host.host
  }

  case class WebmailConfig(enable: Boolean
    , defaultLanguage: String
    , downloadTemplates: Map[String, Template]
    , aliasTemplates: Map[String, Template]
    , notifyTemplates: Map[String, Template]) {

    def findDownloadTemplate(lang: String): Option[(String, Template)] =
      downloadTemplates.find(_._1 == lang)

    def findAliasTemplate(lang: String): Option[(String, Template)] =
      aliasTemplates.find(_._1 == lang)
  }

  case class LogConfig(config: Path) {
    def exists = config.exists && !config.isDirectory
  }

  case class UploadConfig(
    chunkSize: Size
      , simultaneousUploads: Int
      , maxFiles: Int
      , maxFileSize: Size
      , maxValidity: Duration
      , aliasDeleteTime: Duration
      , enableUploadNotification: Boolean
      , cleanupEnable: Boolean
      , cleanupInterval: Duration
      , cleanupInvalidAge: Duration
  )


  trait Config {
    def jdbc: Jdbc
    def authConfig: AuthConfig
    def authcCommand: AuthcCommand
    def authcHttp: AuthcHttp
    def adminAccount: AdminAccount
    def webConfig: WebConfig
    def uploadConfig: UploadConfig
    def logConfig: LogConfig
    def smtpConfig: SmtpSetting
    def smtpSetting: GetSetting =
      if (smtpConfig.host.isEmpty) (GetSetting.fromDomain andThen (_.map(_.copy(from = smtpConfig.from))))
      else GetSetting.of(smtpConfig)
    def webmailConfig: WebmailConfig
  }

  object Config {
    object default extends Config {
      val jdbc: Jdbc = loadConfig[Jdbc]("sharry.db").get
      val authConfig: AuthConfig = loadConfig[AuthConfig]("sharry.authc").get
      val authcCommand: AuthcCommand = loadConfig[AuthcCommand]("sharry.authc.extern.command").get
      val authcHttp: AuthcHttp = loadConfig[AuthcHttp]("sharry.authc.extern.http").get
      val adminAccount = loadConfig[AdminAccount]("sharry.authc.extern.admin").get
      val webConfig = loadConfig[WebConfig]("sharry.web").get
      val uploadConfig = loadConfig[UploadConfig]("sharry.upload").get
      val logConfig = loadConfig[LogConfig]("sharry.log").get
      val smtpConfig: SmtpSetting = loadConfig[SmtpSetting]("sharry.smtp").get
      val webmailConfig: WebmailConfig = loadConfig[WebmailConfig]("sharry.web.mail").get
    }
    implicit final class ConfigEitherOps[A](r: Either[ConfigReaderFailures, A]) {
      def get: A = r match {
        case Right(a) => a
        case Left(errs) => sys.error(errs.toString)
      }
    }
  }

  implicit def hint[T] = ProductHint[T](ConfigFieldMapping(CamelCase, KebabCase))

  implicit def templateConvert: ConfigReader[Template] = ConfigReader.fromString[Template](catchReadError(s =>
    mustache.parse(s) match {
      case Right(t) => t
      case Left(err) => throw new IllegalArgumentException(s"Template parsing failed: $err")
    }
  ))

  implicit def durationConvert: ConfigReader[Duration] = ConfigReader.fromString[Duration](catchReadError(s =>
    Duration.unsafeParse(s)
  ))


  implicit def bytevectorConvert: ConfigReader[ByteVector] =
    ConfigReader.fromString[ByteVector](catchReadError(s =>
      s.span(_ != ':') match {
        case ("", "") => ByteVector(UUID.randomUUID.toString.getBytes)
        case ("b64", value) => ByteVector.fromValidBase64(value.drop(1))
        case ("hex", value) => ByteVector.fromValidHex(value.drop(1))
        case _ => throw new IllegalArgumentException(s"invalid bytes: $s. Make sure to prefix with either 'b64:' or 'hex:'.")
      }))

  //we cannot delegate to Config#getBytes; see https://github.com/melrief/pureconfig/issues/86
  implicit def sizeConvert: ConfigReader[Size] =
    ConfigReader.fromString[Size](
      catchReadError(
        sz => sz.toLowerCase.last match {
          case 'k' => KBytes(sz.dropRight(1).toDouble)
          case 'm' => MBytes(sz.dropRight(1).toDouble)
          case 'g' => GBytes(sz.dropRight(1).toDouble)
          case _ => Bytes(sz.toLong)
        }))

}
