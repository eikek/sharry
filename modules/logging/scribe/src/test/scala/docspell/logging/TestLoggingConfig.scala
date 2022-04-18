/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import munit.Suite
import sharry.logging._
import sharry.logging.impl.ScribeConfigure

trait TestLoggingConfig extends Suite {
  def docspellLogConfig: LogConfig = LogConfig(Level.Warn, LogConfig.Format.Fancy)
  def rootMinimumLevel: Level = Level.Error

  override def beforeAll(): Unit = {
    super.beforeAll()
    val docspellLogger = scribe.Logger("docspell")
    ScribeConfigure.unsafeConfigure(docspellLogger, docspellLogConfig)
    val rootCfg = docspellLogConfig.copy(minimumLevel = rootMinimumLevel)
    ScribeConfigure.unsafeConfigure(scribe.Logger.root, rootCfg)
    ()
  }

}
