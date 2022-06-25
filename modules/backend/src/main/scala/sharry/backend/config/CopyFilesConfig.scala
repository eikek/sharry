package sharry.backend.config

import cats.data.{Validated, ValidatedNec}

import sharry.common.Ident

case class CopyFilesConfig(
    enable: Boolean,
    source: Ident,
    target: Ident,
    parallel: Int
) {

  def validate: ValidatedNec[String, Unit] =
    if (source == target) Validated.invalidNec("Source and target must not be the same")
    else Validated.validNec(())
}
