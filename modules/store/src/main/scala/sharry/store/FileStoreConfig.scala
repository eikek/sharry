package sharry.store

import javax.sql.DataSource

import cats.effect.Async
import fs2.io.file.Path

import binny.fs.{FsChunkedBinaryStore, FsChunkedStoreConfig}
import binny.jdbc.{GenericJdbcStore, JdbcStoreConfig}
import binny.minio.{MinioChunkedBinaryStore, MinioConfig, S3KeyMapping}
import binny.tika.TikaContentTypeDetect
import binny.util.Logger

sealed trait FileStoreConfig {
  def enabled: Boolean
  def storeType: FileStoreType
}
object FileStoreConfig {
  case class DefaultDatabase(enabled: Boolean) extends FileStoreConfig {
    val storeType = FileStoreType.DefaultDatabase
  }

  case class FileSystem(
      enabled: Boolean,
      directory: Path
  ) extends FileStoreConfig {
    val storeType = FileStoreType.FileSystem
  }

  case class S3(
      enabled: Boolean,
      endpoint: String,
      accessKey: String,
      secretKey: String,
      bucket: String
  ) extends FileStoreConfig {
    val storeType = FileStoreType.S3

    override def toString =
      s"S3(enabled=$enabled, endpoint=$endpoint, bucket=$bucket, accessKey=$accessKey, secretKey=***)"
  }

  def createBinaryStore[F[_]: Async](ds: DataSource, chunkSize: Int)(
      config: FileStoreConfig
  ) = {
    val logger = SharryLogger(sharry.logging.getLogger[F])
    config match {
      case DefaultDatabase(_) =>
        val cfg = JdbcStoreConfig("filechunk", chunkSize, TikaContentTypeDetect.default)
        GenericJdbcStore[F](ds, logger, cfg)

      case FileSystem(_, baseDir) =>
        val cfg = FsChunkedStoreConfig
          .defaults(baseDir)
          .copy(chunkSize = chunkSize)
          .withContentTypeDetect(TikaContentTypeDetect.default)
        FsChunkedBinaryStore(logger, cfg)

      case S3(_, endpoint, accessKey, secretKey, bucket) =>
        val cfg = MinioConfig
          .default(
            endpoint,
            accessKey,
            secretKey,
            S3KeyMapping.constant(bucket)
          )
          .copy(chunkSize = chunkSize)
          .withContentTypeDetect(TikaContentTypeDetect.default)
        MinioChunkedBinaryStore(cfg, logger)
    }
  }

  object SharryLogger {
    def apply[F[_]](log: sharry.logging.Logger[F]): Logger[F] =
      new Logger[F] {
        override def trace(msg: => String): F[Unit] =
          log.trace(msg)

        override def debug(msg: => String): F[Unit] =
          log.debug(msg)

        override def info(msg: => String): F[Unit] =
          log.info(msg)

        override def warn(msg: => String): F[Unit] =
          log.warn(msg)

        override def error(msg: => String): F[Unit] =
          log.error(msg)

        override def error(ex: Throwable)(msg: => String): F[Unit] =
          log.error(ex)(msg)
      }
  }
}
