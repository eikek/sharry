package sharry.common

case class Banner(
    version: String,
    gitHash: Option[String],
    jdbcUrl: LenientUri,
    configFile: Option[String],
    baseUrl: LenientUri,
    fileStoreConfig: String
) {

  private val banner =
    """ __ _
      |/ _\ |__   __ _ _ __ _ __ _   _
      |\ \| '_ \ / _` | '__| '__| | | |
      |_\ \ | | | (_| | |  | |  | |_| |
      |\__/_| |_|\__,_|_|  |_|   \__, |
      |                          |___/
      |""".stripMargin +
      s"""     v$version (#${gitHash.map(_.take(8)).getOrElse("")})"""

  def render(prefix: String): String = {
    val text = banner.split('\n').toList ++ List(
      s"Base-Url: ${baseUrl.asString}",
      s"Database: ${jdbcUrl.asString}",
      s"Config:   ${configFile.getOrElse("")}",
      s"FileRepo: $fileStoreConfig",
      ""
    )

    text.map(line => s"$prefix  $line").mkString("\n")
  }
}
