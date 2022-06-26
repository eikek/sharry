package sharry.store

import cats.data.{Validated, ValidatedNec}

case class ComputeChecksumConfig(
    enable: Boolean,
    capacity: Int,
    parallel: Int,
    useDefault: Boolean
) {

  def validate: ValidatedNec[String, ComputeChecksumConfig] =
    if (capacity <= 0) Validated.invalidNec("Capacity must be > 0!")
    else if (useDefault)
      Validated.validNec(copy(parallel = ComputeChecksumConfig.defaultParallel))
    else if (parallel < 0) Validated.invalidNec("Parallel must be > 0!")
    else Validated.validNec(this)

  override def toString: String =
    s"ComputeChecksumConfig(capacity=$capacity, parallel=$parallel, default: $useDefault)"
}

object ComputeChecksumConfig {
  val defaultParallel: Int = math.min(8, math.max(parallelMin, parallelMax))

  val default = ComputeChecksumConfig(true, 5000, 0, true)

  private def parallelMin: Int = 1
  private def parallelMax: Int = Runtime.getRuntime.availableProcessors() - 1
}
