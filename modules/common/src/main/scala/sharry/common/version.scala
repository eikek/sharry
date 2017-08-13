package sharry.common

object version {
  def longVersion: String = {
    val v =
      BuildInfo.version +
      BuildInfo.gitDescribedVersion.map(c => s" ($c)").getOrElse("")

    if (BuildInfo.gitUncommittedChanges) v + " [dirty workingdir]" else v
  }

  def shortVersion = BuildInfo.version

  def projectString: String = {
    s"Sharry ${longVersion}"
  }
}
