package sharry.server

import java.nio.file.Path
import java.time.Duration
import java.util.UUID
import scala.concurrent.duration.FiniteDuration
import com.typesafe.config.ConfigValue
import scodec.bits.ByteVector
import fs2.Task
import doobie.hikari.hikaritransactor._
import pureconfig._
import pureconfig.error._
import pureconfig.ConvertHelpers._
import spinoco.protocol.http.Uri
import sharry.store.data.sizes._
import sharry.store.data.file._

object config {

  case class Jdbc(driver: String, url: String, user: String, password: String) {
    def transactor: Task[HikariTransactor[Task]] =
      HikariTransactor[Task](driver, url, user, password)
  }

  case class AuthConfig(enable: Boolean, defaultUser: String, maxCookieLifetime: Duration, appKey: ByteVector)

  case class AuthcCommand(enable: Boolean, program: Seq[String], success: Int)

  case class AuthcHttp(enable: Boolean, url: String, method: String, body: String, contentType: String)

  case class AdminAccount(enable: Boolean, login: String, password: String)

  case class WebConfig(bindHost: String, bindPort: Int, appName: String, baseurl: String) {
    lazy val domain = Uri.parse(baseurl).require.host.host
  }

  case class LogConfig(config: Path) {
    def exists = config.exists && !config.isDirectory
  }

  case class UploadConfig(
    chunkSize: Size
      , simultaneousUploads: Int
      , maxFiles: Int
      , maxFileSize: Size
      , aliasDeleteTime: Duration
      , cleanupEnable: Boolean
      , cleanupInterval: FiniteDuration
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
    }
    implicit final class ConfigEitherOps[A](r: Either[ConfigReaderFailures, A]) {
      def get: A = r match {
        case Right(a) => a
        case Left(errs) => sys.error(errs.toString)
      }
    }
  }

  implicit def hint[T] = ProductHint[T](ConfigFieldMapping(CamelCase, KebabCase))

  implicit def durationConvert: ConfigReader[Duration] = {
    val dc = implicitly[ConfigReader[scala.concurrent.duration.Duration]]
    new ConfigReader[Duration] {
      def from(v: ConfigValue) =
        dc.from(v).map(fd => Duration.ofNanos(fd.toNanos))
    }
  }

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
