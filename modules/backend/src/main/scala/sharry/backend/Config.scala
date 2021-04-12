package sharry.backend

import sharry.backend.auth.AuthConfig
import sharry.backend.job.CleanupConfig
import sharry.backend.mail.MailConfig
import sharry.backend.share.ShareConfig
import sharry.backend.signup.SignupConfig
import sharry.store.JdbcConfig

case class Config(
    jdbc: JdbcConfig,
    signup: SignupConfig,
    auth: AuthConfig,
    share: ShareConfig,
    cleanup: CleanupConfig,
    mail: MailConfig
)

object Config {}
