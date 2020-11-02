package sharry.store

object PermanentError {
  def create(checks: Seq[DomainCheckConfig]): Extractor =
    new Extractor {
      def unapply(ex: Throwable): Option[String] = {
        val msg = ex.getMessage.toLowerCase
        checks.filter(_.enabled).find(checkMatches(msg)).map(_.message)
      }
    }

  trait Extractor {
    def unapply(ex: Throwable): Option[String]
  }

  private def checkMatches(error: String)(check: DomainCheckConfig): Boolean = {
    val needle = check.native.toLowerCase
    error.contains(needle)
  }
}
