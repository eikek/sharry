package sharry.backend.job

import cats.effect._
import cats.implicits._
import fs2.Stream

import sharry.backend.share._
import sharry.backend.signup._
import sharry.logging.Logger

object PeriodicCleanup {
  def resource[F[_]: Async](
      cleanupCfg: CleanupConfig,
      signupCfg: SignupConfig,
      shareOps: OShare[F],
      signupOps: OSignup[F]
  ): Resource[F, Unit] = {
    val logger = sharry.logging.getLogger[F]

    if (!cleanupCfg.enabled)
      Resource.eval(logger.info("Cleanup job not running, because it is disabled"))
    else {
      val main =
        (logStarting(cleanupCfg, logger) ++ loop(
          cleanupCfg,
          signupCfg,
          shareOps,
          signupOps,
          logger
        ) ++ logStopped(logger)).compile.drain
      Resource
        .make(Async[F].start(main))(fiber =>
          logger.debug("Periodic cleanup cancelled") *> fiber.cancel
        )
        .map(_ => ())
    }
  }

  def loop[F[_]: Async](
      cleanupCfg: CleanupConfig,
      signupCfg: SignupConfig,
      shareOps: OShare[F],
      signupOps: OSignup[F],
      logger: Logger[F]
  ): Stream[F, Nothing] =
    Stream.awakeEvery[F](cleanupCfg.interval.toScala).flatMap { _ =>
      Stream
        .eval(
          logger.info("Running periodic tasks") *>
            doCleanup(cleanupCfg, signupCfg, shareOps, signupOps, logger) *> logger
              .info("Periodic tasks done.")
        )
        .drain
    }

  private def logStarting[F[_]](cleanupCfg: CleanupConfig, logger: Logger[F]) =
    logger.stream
      .info(
        s"Periodic cleanup job active and will run every ${cleanupCfg.interval}. " ++
          s"Will remove published shares expired for at least ${cleanupCfg.invalidAge}."
      )
      .drain

  private def logStopped[F[_]](logger: Logger[F]) =
    logger.stream.info("Periodic cleanup job stopped").drain

  def doCleanup[F[_]: Async](
      cleanupCfg: CleanupConfig,
      signupCfg: SignupConfig,
      shareOps: OShare[F],
      signupOps: OSignup[F],
      logger: Logger[F]
  ): F[Unit] =
    for {
      _ <- logger.debug("Cleanup expired shares...")
      shareN <- shareOps.cleanupExpired(cleanupCfg.invalidAge)
      _ <- logger.info(s"Cleaned up $shareN expired shares.")
      _ <- logger.debug("Cleanup expired invites...")
      invN <- signupOps.cleanInvites(signupCfg)
      _ <- logger.info(s"Removed $invN expired invitations.")
      _ <- logger.debug("Deleting orphaned files ...")
      orphN <- shareOps.deleteOrphanedFiles
      _ <- logger.info(s"Deleted $orphN orphaned files.")
    } yield ()

}
