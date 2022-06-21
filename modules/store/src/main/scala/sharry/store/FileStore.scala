package sharry.store

import javax.sql.DataSource

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Chunk

import sharry.common._
import sharry.store.doobie.AttributeStore
import sharry.store.records.RFileMeta

import _root_.doobie._
import binny._
import binny.fs.{FsChunkedBinaryStore, FsChunkedStoreConfig}
import binny.jdbc.{GenericJdbcStore, JdbcStoreConfig}
import binny.minio.{MinioChunkedBinaryStore, MinioConfig, S3KeyMapping}
import binny.tika.TikaContentTypeDetect
import binny.util.Logger

trait FileStore[F[_]] {

  def chunkSize: Int

  def delete(id: Ident): F[Unit]

  def findMeta(id: Ident): OptionT[F, RFileMeta]

  def findBinary(id: Ident, range: ByteRange): OptionT[F, Binary[F]]

  def insert(data: Binary[F], hint: Hint, created: Timestamp): F[RFileMeta]

  def insertMeta(meta: RFileMeta): F[Unit]

  def addChunk(id: Ident, hint: Hint, chunkDef: ChunkDef, data: Chunk[Byte]): F[Unit]
}

object FileStore {

  def apply[F[_]: Async](
      ds: DataSource,
      xa: Transactor[F],
      chunkSize: Int,
      config: FileStoreConfig
  ): FileStore[F] =
    config match {
      case FileStoreConfig.DefaultDatabase(_) =>
        forDatabase(ds, xa, chunkSize)

      case c: FileStoreConfig.S3 =>
        forS3(xa, c, chunkSize)

      case c: FileStoreConfig.FileSystem =>
        forFs(xa, c, chunkSize)
    }

  def forDatabase[F[_]: Async](
      ds: DataSource,
      xa: Transactor[F],
      chunkSize: Int
  ): FileStore[F] = {
    val cfg = JdbcStoreConfig("filechunk", chunkSize, TikaContentTypeDetect.default)
    val as = AttributeStore(xa)
    val logger = SharryLogger(sharry.logging.getLogger[F])
    val bs = GenericJdbcStore[F](ds, logger, cfg, as)
    new Impl[F](bs, as, chunkSize)
  }

  def forFs[F[_]: Async](
      xa: Transactor[F],
      fsCfg: FileStoreConfig.FileSystem,
      chunkSize: Int
  ): FileStore[F] = {
    val as = AttributeStore(xa)
    val logger = SharryLogger(sharry.logging.getLogger[F])
    val cfg = FsChunkedStoreConfig
      .defaults(fsCfg.directory)
      .copy(chunkSize = chunkSize)
      .withContentTypeDetect(TikaContentTypeDetect.default)
    val bs = FsChunkedBinaryStore(cfg, logger, as)
    new Impl[F](bs, as, chunkSize)
  }

  def forS3[F[_]: Async](
      xa: Transactor[F],
      s3: FileStoreConfig.S3,
      chunkSize: Int
  ): FileStore[F] = {
    val as = AttributeStore(xa)
    val logger = SharryLogger(sharry.logging.getLogger[F])
    val cfg = MinioConfig
      .default(
        s3.endpoint,
        s3.accessKey,
        s3.secretKey,
        S3KeyMapping.constant(s3.bucket)
      )
      .copy(chunkSize = chunkSize)
      .withContentTypeDetect(TikaContentTypeDetect.default)
    val bs = MinioChunkedBinaryStore(cfg, as, logger)
    new Impl[F](bs, as, chunkSize)
  }

  final private class Impl[F[_]: Sync](
      bs: ChunkedBinaryStore[F],
      attrStore: AttributeStore[F],
      val chunkSize: Int
  ) extends FileStore[F] {

    def delete(id: Ident): F[Unit] =
      bs.delete(BinaryId(id.id))

    def findMeta(id: Ident): OptionT[F, RFileMeta] =
      attrStore.findMeta(BinaryId(id.id))

    def findBinary(id: Ident, range: ByteRange): OptionT[F, Binary[F]] =
      bs.findBinary(BinaryId(id.id), range)

    def insert(data: Binary[F], hint: Hint, created: Timestamp): F[RFileMeta] =
      data
        .through(bs.insert(hint))
        .evalTap(id => attrStore.updateCreated(id, created))
        .evalMap(id => attrStore.findMeta(id).value)
        .unNoneTerminate
        .compile
        .lastOrError

    def insertMeta(meta: RFileMeta): F[Unit] =
      attrStore.saveMeta(meta)

    def addChunk(
        id: Ident,
        hint: Hint,
        chunkDef: ChunkDef,
        data: Chunk[Byte]
    ): F[Unit] =
      bs.insertChunk(BinaryId(id.id), chunkDef, hint, data.toByteVector).flatMap {
        case _: InsertChunkResult.Success => ().pure[F]
        case fail => Sync[F].raiseError(new Exception(s"Inserting chunk failed: $fail"))
      }
  }

  private object SharryLogger {

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
