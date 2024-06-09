package sharry.backend.files

import cats.data.OptionT
import cats.effect._
import cats.syntax.all._

import sharry.backend.config.FilesConfig
import sharry.common.Ident
import sharry.store.{FileStoreConfig, Store}

import binny.{AttributeName, CopyTool}

trait OFiles[F[_]] {

  def computeBackgroundChecksum: Resource[F, F[Outcome[F, Throwable, Unit]]]

  def copyFiles(source: FileStoreConfig, target: FileStoreConfig): F[Int]

  def copyFiles(source: Ident, target: Ident): F[Int]
}

object OFiles {

  def apply[F[_]: Async](
      store: Store[F],
      fileConfig: FilesConfig
  ): OFiles[F] =
    new OFiles[F] {
      private val logger = sharry.logging.getLogger[F]

      def computeBackgroundChecksum: Resource[F, F[Outcome[F, Throwable, Unit]]] =
        Async[F].background(
          store.fileStore.computeAttributes
            .consumeAll(AttributeName.all)
            .evalMap(store.fileStore.updateChecksum)
            .compile
            .drain
        )

      def copyFiles(source: Ident, target: Ident): F[Int] =
        (for {
          src <- OptionT.fromOption[F](fileConfig.enabledStores.get(source))
          trg <- OptionT.fromOption[F](fileConfig.enabledStores.get(target))
          r <- OptionT.liftF(copyFiles(src, trg))
        } yield r).getOrElseF(
          Sync[F].raiseError(
            new IllegalArgumentException(
              s"Source or target store not found for keys: ${source.id} and ${target.id}"
            )
          )
        )

      def copyFiles(source: FileStoreConfig, target: FileStoreConfig): F[Int] = {
        val srcF = store.fileStore.createBinaryStore(source)
        val trgF = store.fileStore.createBinaryStore(target)
        val binnyLogger = FileStoreConfig.SharryLogger(logger)

        logger.info(s"Starting to copy $source -> $target") *>
          (srcF, trgF).flatMapN { (src, trg) =>
            CopyTool
              .copyAll(
                binnyLogger,
                src,
                trg,
                store.fileStore.chunkSize,
                fileConfig.copyFiles.parallel
              )
              .flatTap { r =>
                logger.info(
                  s"Copied ${r.success} files, ${r.exist} existed already and ${r.notFound} were not found."
                ) *> (if (r.failed.nonEmpty)
                        logger.warn(s"Failed to copy these files: ${r.failed}")
                      else ().pure[F])
              }
              .map(_.success)
          }
      }
    }
}
