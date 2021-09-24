package sharry.restserver.routes

import cats.data.EitherT
import cats.data.OptionT
import cats.effect._
import cats.implicits._

import sharry.backend.BackendApp
import sharry.backend.auth.AuthToken
import sharry.backend.mail.{MailData, MailSendResult}
import sharry.common._
import sharry.common.syntax.all._
import sharry.restapi.model.BasicResult
import sharry.restapi.model.MailTemplate
import sharry.restapi.model.SimpleMail
import sharry.restserver.Config
import sharry.restserver.http4s.ClientRequestInfo

import emil.MailAddress
import emil.javamail.syntax._
import org.http4s.HttpRoutes
import org.http4s.Request
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.log4s.getLogger

object MailRoutes {

  private[this] val logger = getLogger

  def apply[F[_]: Async](
      backend: BackendApp[F],
      token: AuthToken,
      cfg: Config
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    def baseurl(req: Request[F]) =
      ClientRequestInfo.getBaseUrl(cfg, req) / "app"

    HttpRoutes.of {
      case req @ GET -> Root / "template" / "alias" / Ident(id) =>
        for {
          md <- backend.mail.getAliasTemplate(token.account, id, baseurl(req) / "share")
          resp <- Ok(MailTemplate(md.subject, md.body))
        } yield resp

      case req @ GET -> Root / "template" / "share" / Ident(id) =>
        (for {
          md <- backend.mail.getShareTemplate(token.account, id, baseurl(req) / "open")
          resp <- OptionT.liftF(Ok(MailTemplate(md.subject, md.body)))
        } yield resp).getOrElseF(NotFound())

      case req @ POST -> Root / "send" =>
        def parseAddress(m: SimpleMail): Either[String, List[MailAddress]] =
          m.recipients.traverse(MailAddress.parse)

        def send(rec: List[MailAddress], sm: SimpleMail): F[MailSendResult] =
          backend.mail
            .sendMail(token.account, rec, MailData(sm.subject, sm.body))

        val res = for {
          mail <- EitherT.liftF(req.as[SimpleMail])
          rec <- EitherT.fromEither[F](parseAddress(mail))
          res <- EitherT.liftF[F, String, MailSendResult](send(rec, mail))
          _ <- EitherT.liftF[F, String, Unit](logger.fdebug(s"Sending mail: $res"))
        } yield res

        res.foldF(
          err => Ok(BasicResult(false, s"Some recipient addresses are invalid: $err")),
          r => Ok(mailSendResult(r))
        )
    }
  }

  private def mailSendResult(mr: MailSendResult): BasicResult =
    mr match {
      case MailSendResult.Success => BasicResult(true, "Mail successfully sent.")
      case MailSendResult.SendFailure(ex) =>
        BasicResult(false, s"Mail sending failed: ${ex.getMessage}")
      case MailSendResult.NoRecipients => BasicResult(false, "There are no recipients")
      case MailSendResult.NoSender =>
        BasicResult(
          false,
          "There are no sender addresses specified. You " +
            "may need to add an e-mail address to your account."
        )
      case MailSendResult.FeatureDisabled =>
        BasicResult(false, "The mail feature is disabled")
    }
}
