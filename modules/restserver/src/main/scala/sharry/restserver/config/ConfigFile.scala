package sharry.restserver.config

import sharry.common.config.Implicits._
import sharry.logging.{Level, LogConfig}
import sharry.store.{FileStoreConfig, FileStoreType}

import emil.MailAddress
import emil.SSLType
import emil.javamail.syntax._
import pureconfig._
import pureconfig.generic.auto._
import pureconfig.generic.{CoproductHint, FieldCoproductHint}
import yamusca.imports.{Template, mustache}

object ConfigFile {

  import Implicits._

  def loadConfig: Config =
    ConfigSource.default.at("sharry.restserver").loadOrThrow[Config].validOrThrow

  object Implicits {
    implicit val mailAddressReader: ConfigReader[Option[MailAddress]] =
      ConfigReader[String].emap(
        reason(s =>
          if (s.trim.isEmpty) Right(None) else MailAddress.parse(s).map(m => Some(m))
        )
      )

    implicit val mailSslTypeReader: ConfigReader[SSLType] =
      ConfigReader[String].emap(
        reason(s =>
          s.toLowerCase match {
            case "none"     => Right(SSLType.NoEncryption)
            case "starttls" => Right(SSLType.StartTLS)
            case "ssl"      => Right(SSLType.SSL)
            case _ => Left(s"Invalid ssl type '$s'. Use one of none, ssl or starttls.")
          }
        )
      )

    implicit val templateReader: ConfigReader[Template] =
      ConfigReader[String].emap(
        reason(s =>
          mustache.parse(s).left.map(err => s"Error parsing template at ${err._1.pos}")
        )
      )

    implicit val logFormatReader: ConfigReader[LogConfig.Format] =
      ConfigReader[String].emap(reason(LogConfig.Format.fromString))

    implicit val logLevelReader: ConfigReader[Level] =
      ConfigReader[String].emap(reason(Level.fromString))

    implicit val fileStoreTypeReader: ConfigReader[FileStoreType] =
      ConfigReader[String].emap(reason(FileStoreType.fromString))

    // the value "s-3" looks strange, this is to allow to write "s3" in the config
    implicit val fileStoreCoproductHint: CoproductHint[FileStoreConfig] =
      new FieldCoproductHint[FileStoreConfig]("type") {
        override def fieldValue(name: String) =
          if (name.equalsIgnoreCase("S3")) "s3"
          else super.fieldValue(name)
      }
  }
}
