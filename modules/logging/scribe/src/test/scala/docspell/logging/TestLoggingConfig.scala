/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import sharry.logging._
import sharry.logging.impl.ScribeConfigure

import munit.Suite

trait TestLoggingConfig extends Suite {
  def docspellLogConfig: LogConfig =
    LogConfig(Level.Warn, LogConfig.Format.Fancy, Map.empty)
  def rootMinimumLevel: Level = Level.Error

  override def beforeAll(): Unit = {
    super.beforeAll()
    ScribeConfigure.unsafeConfigure(docspellLogConfig)
  }
}
