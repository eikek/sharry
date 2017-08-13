package sharry.cli

import sharry.cli.cmds._
import sharry.cli.config._

trait maincmds {

  private val loginCmd: Cmd =
    sendPrepare >> loadServerSettings >> validateContext >> checkVersions >> login

  private val publishIf: Cmd = Cmd.choice { ctx =>
    ctx.config.mode match {
      case Mode.PublishFiles => publishUpload
      case Mode.MdPublish => publishUpload
      case _ => Cmd.identity
    }
  }

  private val fileUpload: Cmd = Cmd(checkResumeFile
    , loginCmd
    , refreshCookie
    , createUpload
    , writeResumeFile
    , uploadAllFiles(FileId.default)
    , deleteResumeFile)

  /** Task to upload files. */
  def upload: Cmd = fileUpload

  /** Task to upload and publish files. */
  val publish: Cmd =
    fileUpload >> publishUpload

  /** Resume an upload */
  val resumeContinue: Cmd = Cmd(loadResumeFile
    , loginCmd
    , refreshCookie
    , uploadAllFiles(FileId.default)
    , deleteResumeFile
    , publishIf)

  /** Abort an upload */
  val resumeAbort: Cmd = Cmd(loadResumeFile
    , loginCmd
    , deleteUpload
    , deleteResumeFile)

  val mdUpload: Cmd =
    processMarkdown(FileId.default) >> fileUpload

  val mdPublish: Cmd = Cmd(processMarkdown(FileId.default)
    , fileUpload
    , publishUpload)
}

object maincmds extends maincmds
