package sharry.cli

import sharry.common.duration._
import java.nio.file.Path

import spinoco.protocol.http.{Uri, HostPort}
import sharry.common.{version => sharryVersion}
import sharry.cli.config._

object parser {
  implicit private def uriRead: scopt.Read[Uri] =
    scopt.Read.reads(Config.readUriOrThrow)

  implicit private def durationRead: scopt.Read[Duration] =
    scopt.Read.reads(Config.readDurationOrThrow)

  implicit private def pathRead: scopt.Read[Path] =
    scopt.Read.reads(Config.readExistingPathOrThrow)

  val optionParser = new scopt.OptionParser[Config]("sharry") {
    head("Sharry", sharryVersion.longVersion)

    help("help").text("Prints this help message.")
    version("version").text("Prints version info")

    opt[Path]("config").action((file, c) => c.copy(source = Some(file))).
      valueName("<file>").
      text("Specify a configuration file to read instead of using the default location.")

    opt[String]("loglevel").action((level, c) => c.copy(loglevel = level)).
      text("Set a logging level: off,error,warn,info,debug,trace. Default is off.\n")

    cmd(Mode.UploadFiles.name).action((_, c) => c.copy(mode = Mode.UploadFiles)).
      text("Upload files without publishing them.").
      children((mdOpts ++ descriptionOpts ++ manyFiles): _*)

    cmd(Mode.PublishFiles.name).action((_, c) => c.copy(mode = Mode.PublishFiles)).
      text("Upload and publish some files").
      children((mdOpts ++ descriptionOpts ++ manyFiles): _*)

    cmd(Mode.MdUpload.name).action((_, c) => c.copy(mode = Mode.MdUpload)).
      text("Upload a markdown file together with its referenced files").
      children((mdOpts ++ oneMdFile): _*)

    cmd(Mode.MdPublish.name).action((_, c) => c.copy(mode = Mode.MdPublish)).
      text("Publish a markdown file together with its referenced files").
      children((mdOpts ++ oneMdFile): _*)

    cmd(Mode.Resume(false).name).action((_, c) => c.copy(mode = Mode.Resume(false))).
      text("Resume an uncompleted upload").
      children(
        opt[Unit]("continue").
          text("Resume an uncompleted upload").
          action((_, c) => c.copy(mode = Mode.Resume(false))),
        opt[Unit]("abort").
          text("Abort uncompleted upload\n").
          action((_, c) => c.copy(mode = Mode.Resume(true))))

    cmd(Mode.Manual(false).name).action((_, c) => c.copy(mode = Mode.Manual(false))).
      text("Show the man page, either as markdown or html").
      children(
        opt[Unit]("html").
          text("Print man page as HTML").
          action((_, c) => c.copy(mode = Mode.Manual(true))),
        opt[Unit]("text").
          text("Print man page as text (the default)").
          action((_, c) => c.copy(mode = Mode.Manual(false))))


    checkConfig(cfg => cfg.mode match {
      case _: Mode.Resume => Right(())
      case _: Mode.Manual => Right(())
      case _ =>
        cfg.endpoint match {
          case Uri(_, HostPort("nothing", _), _, _) =>
            Left("A sharry endpoint url is required.")
          case _ => Right(())
        }
    })
    checkConfig(cfg => cfg.auth match {
      case AuthMethod.AliasHeader("") => Left("An alias id or a username/pass pair is required.")
      case AuthMethod.UserLogin("", _, _) => Left("An alias id or a username/pass pair is required.")
      case _ => Right(())
    })

    private def mdOpts = Seq(
      opt[String]("alias").
        text("The alias id for uploading").
        action((id, c) => c.copy(auth = AuthMethod.AliasHeader(id))),
      opt[Uri]("endpoint").
        text("The sharry server url").
        action((url, c) => c.copy(endpoint = url)),
      opt[String]("login").
        text("The login for authenticating with the server").
        action((login, c) => c.copy(auth = c.auth match {
          case AuthMethod.UserLogin(_, pass, passCmd) => AuthMethod.UserLogin(login, pass, passCmd)
          case _ =>  AuthMethod.UserLogin(login, "", "")
        })),
      opt[String]("pass").
        text("The password for authenticating with the server").
        action((pw, c) => c.copy(auth = c.auth match {
          case AuthMethod.UserLogin(login, _, passCmd) => AuthMethod.UserLogin(login, pw, "")
          case _ =>  AuthMethod.UserLogin("", pw, "")
        })),
      opt[Duration]("valid").
        text("The validity for this upload").
        action((d, c) => c.copy(valid = d)),
      opt[Int]("max-downloads").
        text("Maximum number of downloads for the upload").
        action((n, c) => c.copy(maxDownloads = n)),
      opt[String]("password").
        text("The password to protect the upload with").
        action((pw, c) => c.copy(password = Some(pw))),
      opt[Int]("parallel-uploads").
        text("Number of parallel uploads.").
        action((n, c) => c.copy(parallelUploads = Some(n)))
    )

    private def descriptionOpts =
      Seq(
        opt[String]("description").
          text("The description of the upload (maybe markdown)").
          action((s, c) => c.copy(description = Some(s))),
        opt[Path]("@description").
          valueName("<file>").
          text("Use contents of the given file as description").
          action((p, c) => c.copy(descriptionFile = Some(p)))
      )

    private def oneMdFile = Seq(
      arg[Path]("<file>").
        required().
        text("The markdown file to inspect and upload\n").
        action((f, c) => c.copy(files = Seq(f)))
    )

    private def manyFiles = Seq(
      arg[Path]("<files> ...").
        text("The files to upload\n").
        required().
        unbounded().
        action((f, c) => c.copy(files = c.files :+ f))
    )
  }
}
