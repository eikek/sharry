package sharry.backend

import sharry.store.JdbcConfig
import sharry.backend.signup.SignupConfig
import sharry.backend.auth.AuthConfig
import sharry.backend.share.ShareConfig
import sharry.backend.job.CleanupConfig
import sharry.backend.mail.MailConfig

case class Config(
    jdbc: JdbcConfig,
    signup: SignupConfig,
    auth: AuthConfig,
    share: ShareConfig,
    cleanup: CleanupConfig,
    mail: MailConfig
)

object Config {}
