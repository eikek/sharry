package sharry.cli

import spinoco.protocol.http.Uri
import sharry.common.sizes._
import sharry.common.BuildInfo
import sharry.cli.config._

sealed trait Progress

object Progress {
  case object Init extends Progress
  case class Prepare(cfg: Config) extends Progress
  case class ServerWelcome(ctx: Context) extends Progress
  case class Authenticating(host: Uri) extends Progress
  case object CreateUpload extends Progress
  case object DeleteUpload extends Progress
  case object PublishUpload extends Progress
  case class VersionMismatch(server: String) extends Progress {
    val cli: String = BuildInfo.version
    val isMismatch: Boolean = cli != server // todo don't compare minors
    override def toString() = s"VersionMismatch(cli = $cli vs. server = $server"
  }
  case class Uploaded(amount: Size, total: Size) extends Progress
  case class Error(exception: Throwable) extends Progress
  case class Done(ctx: Context) extends Progress
  case object ProcessingMarkdown extends Progress
  case class Manual(text: String, html: Boolean) extends Progress
}
