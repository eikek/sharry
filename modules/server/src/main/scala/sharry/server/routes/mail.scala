package sharry.server.routes

import fs2.{Pipe, Stream, Task}
import shapeless.{::,HNil}
import spinoco.fs2.http.HttpResponse
import spinoco.fs2.http.routing._

import sharry.server.paths
import sharry.server.config._
import sharry.server.email._
import sharry.server.routes.syntax._
import sharry.server.jsoncodec._

object mail {

  def endpoint(auth: AuthConfig, smtp: GetSetting, mailCfg: WebmailConfig): Route[Task] =
    choice(checkMailAddress(auth)
      , sendMail(auth, smtp)
      , getDownloadTemplate(auth, mailCfg)
      , getAliasTemplate(auth, mailCfg))


  def checkMailAddress(authCfg: AuthConfig): Route[Task] =
    Get >> paths.mailCheck.matcher >> authz.user(authCfg) >> param[String]("mail") map {
      (mail: String) =>

      Stream.eval(Address.parse(mail)).
        map(_ => Ok[Task,Message](Message("Address is valid"))).
        onError(ex => Stream.emit(BadRequest[Task, Message](Message(ex))))
    }


  def sendMail(authCfg: AuthConfig, smtp: GetSetting): Route[Task] =
    Post >> paths.mailSend.matcher >> authz.user(authCfg) >> jsonBody[SimpleMail] map {
      (mail: SimpleMail) =>

      client.send(smtp)(mail.parse).
        fold(SendResult.empty)({ (r, attempt) =>
          attempt.fold(r.addFailure, r.addSuccess)
        }).
        map({
          case r@SendResult(_, Nil, _) => BadRequest(r.withMessage("No mails could be send."))
          case r@SendResult(_, _, Nil) => Ok(r.withMessage("All mails have been sent."))
          case r => Ok(r.withMessage("Some mails could not be send."))
        })
    }


  def getDownloadTemplate(authCfg: AuthConfig, cfg: WebmailConfig): Route[Task] =
    Get >> paths.mailDownloadTemplate.matcher >> getTemplate(cfg.findDownloadTemplate, authCfg, cfg)

  def getAliasTemplate(authCfg: AuthConfig, cfg: WebmailConfig): Route[Task] =
    Get >> paths.mailAliasTemplate.matcher >> getTemplate(cfg.findAliasTemplate, authCfg, cfg)

  private def getTemplate(f: String => Option[(String, String)], authCfg: AuthConfig, cfg: WebmailConfig): Route[Task] =
    param[String]("url") :: param[String]("lang").? :: authz.user(authCfg) map {
      case url :: optLang :: login :: HNil =>
        val (lang, template) = optLang.
          flatMap(f).
          orElse(f(cfg.defaultLanguage)).
          getOrElse(optLang.getOrElse(cfg.defaultLanguage) -> "")

        val text = template.trim.
          replace("%{url}", url).
          replace("%{username}", login)
        val (subject, body) = text.span(_ != '\n')

        Stream.emit(Ok(Map("lang" -> lang, "text" -> body.trim, "subject" -> subject.trim)))
    }


  case class SimpleMail(to: List[String], subject: String, text: String) {
    def parse: Task[Mail] = Mail(to, subject, text)
  }

  case class SendResult(message: String, success: List[Address], failed: List[String]) {
    def addFailure(msg: Throwable) = copy(failed = msg.getMessage :: failed)
    def addSuccess(mail: Mail) = copy(success = mail.recipients ::: success)
    def withMessage(msg: String) = copy(message = msg)
  }

  object SendResult { val empty = SendResult("", Nil, Nil) }
}
