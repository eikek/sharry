/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package sharry.logging.impl

import cats.effect.Sync
import sharry.logging.LogConfig.Format
import sharry.logging.{Level, LogConfig}
import scribe.format.Formatter
import scribe.jul.JULHandler
import scribe.writer.SystemOutWriter

object ScribeConfigure {
  private[this] val sharryRootVerbose = "SHARRY_ROOT_LOGGER_LEVEL"

  def configure[F[_]: Sync](cfg: LogConfig): F[Unit] =
    Sync[F].delay {
      replaceJUL()
      val sharryLogger = scribe.Logger("sharry")
      unsafeConfigure(scribe.Logger.root, cfg.copy(minimumLevel = getRootMinimumLevel))
      unsafeConfigure(sharryLogger, cfg)
      unsafeConfigure(scribe.Logger("org.flywaydb"), cfg)
      unsafeConfigure(scribe.Logger("binny"), cfg)
      unsafeConfigure(scribe.Logger("org.http4s"), cfg)
    }

  def getRootMinimumLevel: Level =
    Option(System.getenv(sharryRootVerbose))
      .map(Level.fromString)
      .flatMap {
        case Right(level) => Some(level)
        case Left(err) =>
          scribe.warn(
            s"Environment variable '$sharryRootVerbose' has invalid value: $err"
          )
          None
      }
      .getOrElse(Level.Error)

  def unsafeConfigure(logger: scribe.Logger, cfg: LogConfig): Unit = {
    val mods: List[scribe.Logger => scribe.Logger] = List(
      _.clearHandlers(),
      _.withMinimumLevel(ScribeWrapper.convertLevel(cfg.minimumLevel)),
      l =>
        if (logger.id == scribe.Logger.RootId) {
          cfg.format match {
            case Format.Fancy =>
              l.withHandler(formatter = Formatter.enhanced, writer = SystemOutWriter)
            case Format.Plain =>
              l.withHandler(formatter = Formatter.classic, writer = SystemOutWriter)
            case Format.Json =>
              l.withHandler(writer = JsonWriter(SystemOutWriter))
            case Format.Logfmt =>
              l.withHandler(writer = LogfmtWriter(SystemOutWriter))
          }
        } else l,
      _.replace()
    )

    mods.foldLeft(logger)((l, mod) => mod(l))
    ()
  }

  def replaceJUL(): Unit = {
    scribe.Logger.system // just to load effects in Logger singleton
    val julRoot = java.util.logging.LogManager.getLogManager.getLogger("")
    julRoot.getHandlers.foreach(julRoot.removeHandler)
    julRoot.addHandler(JULHandler)
  }
}
