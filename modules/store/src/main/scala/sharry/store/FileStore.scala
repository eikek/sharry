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

  def updateChecksum(meta: RFileMeta): F[Unit]

  def addChunk(id: Ident, hint: Hint, chunkDef: ChunkDef, data: Chunk[Byte]): F[Unit]

  def computeAttributes: ComputeChecksum[F]
}

object FileStore {

  def apply[F[_]: Async](
      ds: DataSource,
      xa: Transactor[F],
      chunkSize: Int,
      computeChecksumConfig: ComputeChecksumConfig,
      config: FileStoreConfig
  ): F[FileStore[F]] =
    config match {
      case FileStoreConfig.DefaultDatabase(_) =>
        forDatabase(ds, xa, chunkSize, computeChecksumConfig)

      case c: FileStoreConfig.S3 =>
        forS3(xa, c, chunkSize, computeChecksumConfig)

      case c: FileStoreConfig.FileSystem =>
        forFs(xa, c, chunkSize, computeChecksumConfig)
    }

  def forDatabase[F[_]: Async](
      ds: DataSource,
      xa: Transactor[F],
      chunkSize: Int,
      computeChecksumConfig: ComputeChecksumConfig
  ): F[FileStore[F]] = {
    val cfg = JdbcStoreConfig("filechunk", chunkSize, TikaContentTypeDetect.default)
    val as = AttributeStore(xa)
    val logger = SharryLogger(sharry.logging.getLogger[F])
    val bs = GenericJdbcStore[F](ds, logger, cfg)
    ComputeChecksum[F](bs, computeChecksumConfig).map(cc =>
      new Impl[F](bs, as, chunkSize, cc)
    )
  }

  def forFs[F[_]: Async](
      xa: Transactor[F],
      fsCfg: FileStoreConfig.FileSystem,
      chunkSize: Int,
      computeChecksumConfig: ComputeChecksumConfig
  ): F[FileStore[F]] = {
    val as = AttributeStore(xa)
    val logger = SharryLogger(sharry.logging.getLogger[F])
    val cfg = FsChunkedStoreConfig
      .defaults(fsCfg.directory)
      .copy(chunkSize = chunkSize)
      .withContentTypeDetect(TikaContentTypeDetect.default)
    val bs = FsChunkedBinaryStore(logger, cfg)
    ComputeChecksum[F](bs, computeChecksumConfig).map(cc =>
      new Impl[F](bs, as, chunkSize, cc)
    )
  }

  def forS3[F[_]: Async](
      xa: Transactor[F],
      s3: FileStoreConfig.S3,
      chunkSize: Int,
      computeChecksumConfig: ComputeChecksumConfig
  ): F[FileStore[F]] = {
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
    val bs = MinioChunkedBinaryStore(cfg, logger)
    ComputeChecksum[F](bs, computeChecksumConfig).map(cc =>
      new Impl[F](bs, as, chunkSize, cc)
    )
  }

  final private class Impl[F[_]: Sync](
      bs: ChunkedBinaryStore[F],
      attrStore: AttributeStore[F],
      val chunkSize: Int,
      val computeAttributes: ComputeChecksum[F]
  ) extends FileStore[F] {

    def delete(id: Ident): F[Unit] =
      bs.delete(BinaryId(id.id))

    def findMeta(id: Ident): OptionT[F, RFileMeta] =
      attrStore.findMeta(BinaryId(id.id))

    def findBinary(id: Ident, range: ByteRange): OptionT[F, Binary[F]] =
      bs.findBinary(BinaryId(id.id), range)

    def insert(data: Binary[F], hint: Hint, created: Timestamp): F[RFileMeta] =
      data
        .through(bs.insert)
        .evalMap { id =>
          computeAttributes.submit(id, hint) *>
            computeAttributes
              .computeSync(id, hint, AttributeName.excludeSha256)
              .flatTap(insertMeta)
        }
        .compile
        .lastOrError

    def insertMeta(meta: RFileMeta): F[Unit] =
      attrStore.saveMeta(meta)

    def updateChecksum(meta: RFileMeta): F[Unit] =
      attrStore.updateChecksum(meta.id, meta.checksum)

    def addChunk(
        id: Ident,
        hint: Hint,
        chunkDef: ChunkDef,
        data: Chunk[Byte]
    ): F[Unit] =
      bs.insertChunk(BinaryId(id.id), chunkDef, hint, data.toByteVector).flatMap {
        case InsertChunkResult.Complete =>
          computeAttributes.submit(BinaryId(id.id), hint) *>
            computeAttributes
              .computeSync(BinaryId(id.id), hint, AttributeName.excludeSha256)
              .flatMap(insertMeta)
        case InsertChunkResult.Incomplete => ().pure[F]
        case fail: InsertChunkResult.Failure =>
          Sync[F].raiseError(new Exception(s"Inserting chunk failed: $fail"))
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
