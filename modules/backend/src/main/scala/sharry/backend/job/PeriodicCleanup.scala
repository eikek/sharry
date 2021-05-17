package sharry.backend.job

import cats.effect._
import cats.implicits._
import fs2.Stream

import sharry.backend.share._
import sharry.backend.signup._
import sharry.common.syntax.all._

import org.log4s.getLogger

object PeriodicCleanup {
  private[this] val logger = getLogger

  def resource[F[_]: ConcurrentEffect: Timer](
      cleanupCfg: CleanupConfig,
      signupCfg: SignupConfig,
      shareOps: OShare[F],
      signupOps: OSignup[F]
  ): Resource[F, Unit] =
    if (!cleanupCfg.enabled)
      Resource.eval(logger.finfo("Cleanup job not running, because it is disabled"))
    else {
      val main =
        (logStarting(cleanupCfg) ++ loop(
          cleanupCfg,
          signupCfg,
          shareOps,
          signupOps
        ) ++ logStopped).compile.drain
      Resource
        .make(ConcurrentEffect[F].start(main))(fiber =>
          logger.fdebug("Periodic cleanup cancelled") *> fiber.cancel
        )
        .map(_ => ())
    }

  def loop[F[_]: ConcurrentEffect: Timer](
      cleanupCfg: CleanupConfig,
      signupCfg: SignupConfig,
      shareOps: OShare[F],
      signupOps: OSignup[F]
  ): Stream[F, Nothing] =
    Stream.awakeEvery[F](cleanupCfg.interval.toScala).flatMap { _ =>
      Stream
        .eval(
          logger.finfo("Running periodic tasks") *>
            doCleanup(cleanupCfg, signupCfg, shareOps, signupOps) *> logger
              .finfo("Periodic tasks done.")
        )
        .drain
    }

  private def logStarting[F[_]: Sync](cleanupCfg: CleanupConfig) =
    Stream.eval(logger.finfo(s"Periodic cleanup job active and will run every ${cleanupCfg.interval}. " ++
                             s"Will remove published shares expired for at least ${cleanupCfg.invalidAge}.")).drain

  private def logStopped[F[_]: Sync] =
    Stream.eval(logger.finfo("Periodic cleanup job stopped")).drain

  def doCleanup[F[_]: ConcurrentEffect](
      cleanupCfg: CleanupConfig,
      signupCfg: SignupConfig,
      shareOps: OShare[F],
      signupOps: OSignup[F]
  ): F[Unit] =
    for {
      _      <- logger.fdebug("Cleanup expired shares...")
      shareN <- shareOps.cleanupExpired(cleanupCfg.invalidAge)
      _      <- logger.finfo(s"Cleaned up $shareN expired shares.")
      _      <- logger.fdebug("Cleanup expired invites...")
      invN   <- signupOps.cleanInvites(signupCfg)
      _      <- logger.finfo(s"Removed $invN expired invitations.")
      _      <- logger.fdebug("Deleting orphaned files ...")
      orphN  <- shareOps.deleteOrphanedFiles
      _      <- logger.finfo(s"Deleted $orphN orphaned files.")
    } yield ()

}
