package sharry.server

import cats.effect.IO

/** Utility for sending simple (text) emails. */
package object email {
  type Body = String

  type GetSetting = Address => IO[SmtpSetting]

  object GetSetting {
    def of(s: SmtpSetting): GetSetting =
      _ => IO.pure(s)

    val fromDomain: GetSetting =
      a => SmtpSetting.fromAddress(a).flatMap {
        case Some(s) => IO.pure(s)
        case None => IO.raiseError(new Exception(s"No smtp host found for address $a"))
      }
  }
}
