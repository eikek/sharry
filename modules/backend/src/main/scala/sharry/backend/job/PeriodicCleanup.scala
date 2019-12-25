package sharry.backend.job

import cats.effect._
import cats.implicits._
import fs2.Stream
import sharry.store.Store
import sharry.common._
import sharry.common.syntax.all._
import org.log4s.getLogger
import sharry.backend.share.Queries

object PeriodicCleanup {
  private[this] val logger = getLogger

  def resource[F[_]: ConcurrentEffect: Timer: ContextShift](
      cfg: CleanupConfig,
      store: Store[F]
  ): Resource[F, Unit] =
    if (!cfg.enabled)
      Resource.liftF(logger.finfo("Cleanup job not running, because it is disabled"))
    else {
      val main = (logStarting ++ loop(cfg, store) ++ logStopped).compile.drain
      Resource
        .make(ConcurrentEffect[F].start(main))(
          fiber => logger.fdebug("Periodic cleanup cancelled") *> fiber.cancel
        )
        .map(_ => ())
    }

  def loop[F[_]: ConcurrentEffect: Timer: ContextShift](
      cfg: CleanupConfig,
      store: Store[F]
  ): Stream[F, Nothing] =
    Stream.awakeEvery[F](cfg.interval.toScala).flatMap { _ =>
      Stream
        .eval(
          logger.finfo("Running periodic tasks") *>
            doCleanup(cfg, store) *> deleteOrphanedFiles(store) *> logger
            .finfo("Periodic tasks done.")
        )
        .drain
    }

  private def logStarting[F[_]: Sync] =
    Stream.eval(logger.finfo("Periodic cleanup job active")).drain

  private def logStopped[F[_]: Sync] =
    Stream.eval(logger.finfo("Periodic cleanup job stopped")).drain

  def doCleanup[F[_]: ConcurrentEffect](cfg: CleanupConfig, store: Store[F]): F[Unit] =
    for {
      _     <- logger.finfo("Cleanup expired shares...")
      now   <- Timestamp.current[F]
      point = now.minus(cfg.invalidAge)
      _ <- store
            .transact(Queries.findExpired(point))
            .evalMap(
              id =>
                logger.fdebug(s"Delete expired share: ${id.id}") *> Queries.deleteShare(id, false)(
                  store
                )
            )
            .compile
            .drain
    } yield ()

  def deleteOrphanedFiles[F[_]: ConcurrentEffect](store: Store[F]): F[Unit] =
    for {
      _ <- logger.finfo("Checking for orphaned files...")
      _ <- store
            .transact(Queries.findOrphanedFiles)
            .evalMap(
              id =>
                logger.fdebug(s"Delete orphaned file '${id.id}'") *> Queries.deleteFile(store)(id)
            )
            .compile
            .drain
    } yield ()
}
