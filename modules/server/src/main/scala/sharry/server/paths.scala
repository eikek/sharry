package sharry.server

import cats.effect.IO
import spinoco.fs2.http.routing._

/** Collection of paths used by the rest api and that is transferred
  * to the web client.*/
object paths {
  val api1 = Path("api", "v1")

  val mounts = Map(
    "authLogin" -> api1/"auth"/"login",
    "authCookie" -> api1/"auth"/"cookie",
    "logout" -> api1/"auth"/"logout",
    "accounts" -> api1/"accounts",
    "profileEmail" -> api1/"profile"/"email",
    "profilePassword" -> api1/"profile"/"password",
    "uploads" -> api1/"uploads",
    "uploadData" -> api1/"upload-data",
    "uploadPublish" -> api1/"upload-publish",
    "uploadUnpublish" -> api1/"upload-unpublish",
    "download" -> api1/"dl"/"file",
    "downloadPublished" -> Path("dlp")/"file",
    "checkPassword" -> api1/"check-password",
    "aliases" -> api1/"aliases",
    "mailCheck" -> api1/"mail"/"check",
    "mailSend" -> api1/"mail"/"send",
    "mailDownloadTemplate" -> api1/"mail"/"download-template",
    "mailAliasTemplate" -> api1/"mail"/"alias-template",
    "uploadNotify" -> api1/"upload-notify",
    "manual" -> Path("manual"),
    "settings" -> api1/"settings"
  )

  def authLogin = mounts("authLogin").matcher
  def authCookie = mounts("authCookie").matcher
  def logout = mounts("logout")
  def accounts = mounts("accounts")
  def profileEmail = mounts("profileEmail")
  def profilePassword = mounts("profilePassword")
  def uploads = mounts("uploads")
  def uploadData = mounts("uploadData")
  def uploadPublish = mounts("uploadPublish")
  def uploadUnpublish = mounts("uploadUnpublish")
  def download = mounts("download")
  def downloadPublished = mounts("downloadPublished")
  def checkPassword = mounts("checkPassword")
  def aliases = mounts("aliases")
  def mailCheck = mounts("mailCheck")
  def mailSend = mounts("mailSend")
  def mailDownloadTemplate = mounts("mailDownloadTemplate")
  def mailAliasTemplate = mounts("mailAliasTemplate")
  def uploadNotify = mounts("uploadNotify")
  def manual = mounts("manual")
  def settings = mounts("settings")

  case class Path(segments: List[String]) {
    def matcherF[F[_]]: Matcher[F, String] = segments match {
      case Nil => empty.map(_ => "")
      case a :: Nil => a
      case a :: b :: Nil => a / b
      case a :: b :: rest => rest.foldLeft(a / b)(_ / _)
    }
    def matcher = matcherF[IO]
    def path = segments.mkString("/", "/", "")

    def /(next: String) = Path(segments :+ next)
  }

  object Path {
    val root = Path(Nil)
    def apply(segs: String*): Path =
      if (segs.isEmpty) root
      else Path(segs.toList)
  }
}
