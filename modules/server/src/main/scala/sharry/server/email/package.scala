package sharry.server

import fs2.Task

/** Utility for sending simple (text) emails. */
package object email {
  type Body = String

  type GetSetting = Address => Task[SmtpSetting]

  object GetSetting {
    def of(s: SmtpSetting): GetSetting =
      _ => Task.now(s)

    def fromDomain: GetSetting =
      a => SmtpSetting.fromAddress(a).flatMap {
        case Some(s) => Task.now(s)
        case None => Task.fail(new Exception(s"No smtp host found for address $a"))
      }
  }
}
