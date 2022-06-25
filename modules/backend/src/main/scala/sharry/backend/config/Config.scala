package sharry.backend.config

import cats.data.ValidatedNec
import cats.syntax.all._

import sharry.backend.auth.AuthConfig
import sharry.backend.job.CleanupConfig
import sharry.backend.mail.MailConfig
import sharry.backend.share.ShareConfig
import sharry.backend.signup.SignupConfig
import sharry.store.{ComputeChecksumConfig, JdbcConfig}

case class Config(
    jdbc: JdbcConfig,
    signup: SignupConfig,
    auth: AuthConfig,
    share: ShareConfig,
    cleanup: CleanupConfig,
    mail: MailConfig,
    files: FilesConfig,
    computeChecksum: ComputeChecksumConfig
) {

  def validate: ValidatedNec[String, Config] =
    (files.validate, computeChecksum.validate)
      .mapN((fc, cc) => copy(files = fc, computeChecksum = cc))
}
