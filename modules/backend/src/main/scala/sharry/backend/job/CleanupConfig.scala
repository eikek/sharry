package sharry.backend.job

import sharry.common.*

case class CleanupConfig(enabled: Boolean, interval: Duration, invalidAge: Duration) {}
