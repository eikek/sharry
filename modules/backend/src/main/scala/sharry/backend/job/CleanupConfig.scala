package sharry.backend.job

import sharry.common._

case class CleanupConfig(enabled: Boolean, interval: Duration, invalidAge: Duration) {}
