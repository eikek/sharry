package sharry.backend.signup

import sharry.common._

case class SignupConfig(mode: SignupMode, inviteTime: Duration, invitePassword: Password)

object SignupConfig {}
