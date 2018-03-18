package sharry.server.routes

import fs2.Stream
import cats.effect.IO
import shapeless.{::,HNil}
import spinoco.fs2.http.routing._
import yamusca.imports._
import yamusca.implicits._
import io.circe._, io.circe.generic.semiauto._

import sharry.store.account._
import sharry.server.paths
import sharry.server.config._
import sharry.server.email._
import sharry.server.routes.syntax._

object mail {

  def endpoint(auth: AuthConfig, smtp: GetSetting, mailCfg: WebmailConfig, store: AccountStore): Route[IO] =
    choice2(checkMailAddress(auth)
      , sendMail(auth, mailCfg, smtp, store)
      , getDownloadTemplate(auth, mailCfg)
      , getAliasTemplate(auth, mailCfg))


  def checkMailAddress(authCfg: AuthConfig): Route[IO] =
    Get >> paths.mailCheck.matcher >> authz.user(authCfg) >> param[String]("mail") map {
      (mail: String) =>

      Stream.eval(Address.parse(mail)).
        map(_ => Ok.message("Address is valid")).
        handleErrorWith(ex => Stream.emit(BadRequest.message(ex)))
    }


  def sendMail(authCfg: AuthConfig, cfg: WebmailConfig, smtp: GetSetting, store: AccountStore): Route[IO] =
    Post >> paths.mailSend.matcher >> authz.user(authCfg) :: jsonBody[SimpleMail] map {
      case user :: mail :: HNil =>
        if (!cfg.enable) Stream.emit(BadRequest.message("Sending mails is disabled."))
        else {
          val msg = for {
            msg   <- mail.parse
            acc   <- store.getAccount(user).compile.last
            reply <- acc.flatMap(_.email) match {
              case Some(em) => Address.parse(em).map(Some.apply)
              case None => IO.pure(None)
            }
          } yield reply.map(r => msg.withHeader(Header.GenericHeader("Reply-To", r.mail.toString))).getOrElse(msg)
          client.send(smtp)(msg).
            fold(SendResult.empty)({ (r, attempt) =>
              attempt.fold(r.addFailure, r.addSuccess)
            }).
            map({
              case r@SendResult(_, Nil, _) => Ok.body(r.withMessage("No mails could be send."))
              case r@SendResult(_, _, Nil) => Ok.body(r.withMessage("All mails have been sent."))
              case r => Ok.body(r.withMessage("Some mails could not be send."))
            })
        }
    }


  def getDownloadTemplate(authCfg: AuthConfig, cfg: WebmailConfig): Route[IO] =
    Get >> paths.mailDownloadTemplate.matcher >> getTemplate(cfg.findDownloadTemplate, authCfg, cfg)

  def getAliasTemplate(authCfg: AuthConfig, cfg: WebmailConfig): Route[IO] =
    Get >> paths.mailAliasTemplate.matcher >> getTemplate(cfg.findAliasTemplate, authCfg, cfg)

  private def getTemplate(f: String => Option[(String, Template)], authCfg: AuthConfig, cfg: WebmailConfig): Route[IO] =
    param[String]("url") :: param[String]("lang").? :: param[Boolean]("pass").? :: authz.user(authCfg) map {
      case url :: optLang :: pass :: login :: HNil =>
        val (lang, template) = optLang.
          flatMap(f).
          orElse(f(cfg.defaultLanguage)).
          getOrElse(optLang.getOrElse(cfg.defaultLanguage) -> Template(Literal("")))

        val data = Context("username" -> login.asMustacheValue
          , "url" -> url.asMustacheValue
          , "password" -> pass.asMustacheValue)
        val text = mustache.render(template)(data)
        val (subject, body) = text.span(_ != '\n')

        Stream.emit(Ok.body(Map("lang" -> lang, "text" -> body.trim, "subject" -> subject.trim)))
    }


  case class SimpleMail(to: List[String], subject: String, text: String) {
    def parse: IO[Mail] = Mail(to, subject, text)
  }

  object SimpleMail {
    implicit val _jsonDecoder: Decoder[SimpleMail] = deriveDecoder[SimpleMail]
  }

  case class SendResult(message: String, success: List[Address], failed: List[String]) {
    def addFailure(msg: Throwable) = copy(failed = msg.getMessage :: failed)
    def addSuccess(mail: Mail) = copy(success = mail.recipients ::: success)
    def withMessage(msg: String) = copy(message = msg)
  }

  object SendResult {
    val empty = SendResult("", Nil, Nil)

    implicit val _jsonEncoder: Encoder[SendResult] = deriveEncoder[SendResult]
  }
}
