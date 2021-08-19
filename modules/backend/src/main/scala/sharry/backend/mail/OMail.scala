package sharry.backend.mail

import cats.data.EitherT
import cats.data.OptionT
import cats.effect._
import cats.implicits._

import sharry.backend.mail.MailConfig.MailTpl
import sharry.common._
import sharry.common.syntax.all._
import sharry.store.Store

import emil.builder._
import emil.javamail.syntax._
import emil.{MailConfig => _, _}
import org.log4s.getLogger
import yamusca.implicits._

trait OMail[F[_]] {

  def notifyAliasUpload(
      aliasId: Ident,
      shareId: Ident,
      baseUrl: LenientUri
  ): F[List[NotifyResult]]

  def getShareTemplate(
      acc: AccountId,
      shareId: Ident,
      baseUrl: LenientUri
  ): OptionT[F, MailData]

  def getAliasTemplate(acc: AccountId, aliasId: Ident, baseUrl: LenientUri): F[MailData]

  def sendMail(
      acc: AccountId,
      receiver: List[MailAddress],
      mail: MailData
  ): F[MailSendResult]
}

object OMail {
  private[this] val logger = getLogger

  def apply[F[_]: Async](
      store: Store[F],
      cfg: MailConfig,
      emil: Emil[F]
  ): Resource[F, OMail[F]] =
    Resource.pure[F, OMail[F]](new OMail[F] {

      def notifyAliasUpload(
          aliasId: Ident,
          shareId: Ident,
          baseUrl: LenientUri
      ): F[List[NotifyResult]] = {
        def createMail(tpl: MailTpl, data: TemplateData, receiver: MailAddress): Mail[F] =
          MailBuilder.build(
            From(cfg.smtp.defaultFrom.getOrElse(receiver)),
            To(receiver),
            ListId(cfg.smtp.listId),
            Subject(data.render(tpl.subject)),
            TextBody[F](data.render(tpl.body))
          )

        def send(rec: MailAddress, td: TemplateData): F[NotifyResult] =
          emil(cfg.toEmil)
            .send(createMail(cfg.templates.uploadNotify, td, rec))
            .attempt
            .map {
              case Right(_) => NotifyResult.SendSuccessful(rec)
              case Left(ex) =>
                logger.warn(ex)("Sending failed")
                NotifyResult.SendFailed(rec, ex.getMessage)
            }

        if (!cfg.enabled) List(NotifyResult.featureDisabled).pure[F]
        else
          (for {
            data <- OptionT(store.transact(Queries.findNotifyData(aliasId, shareId)))
            receivers <- OptionT.fromOption[F](
              data.users.traverse(u =>
                MailAddress.parse(u.email).toOption.map(ma => (u.login, ma))
              )
            )
            templates = receivers.map { case (login, mailAddress) =>
              (
                mailAddress,
                TemplateData(login, baseUrl / shareId.id, false, data.aliasName)
              )
            }
            res <- OptionT.liftF(templates.traverse((send _).tupled))
            failedReceiver = res
              .filter(_.isError)
              .flatMap(_.receiver)
              .map(_.displayString)
              .mkString(", ")
            _ <- OptionT.liftF(
              logger.finfo(
                "Send notification mails about upload. " +
                  s"Success ${res.filter(_.isSuccess).size}/${res.size}. " +
                  s"Sending failures for: $failedReceiver"
              )
            )
          } yield res).getOrElse(List(NotifyResult.InvalidAlias))
      }

      def getShareTemplate(
          acc: AccountId,
          shareId: Ident,
          baseUrl: LenientUri
      ): OptionT[F, MailData] =
        for {
          t <- OptionT(store.transact(Queries.publishIdAndPassword(acc.id, shareId)))
          td  = TemplateData(acc.userLogin, baseUrl / t._2.id, t._1, "")
          tpl = cfg.templates.download
        } yield MailData(td.render(tpl.subject), td.render(tpl.body))

      def getAliasTemplate(
          acc: AccountId,
          aliasId: Ident,
          baseUrl: LenientUri
      ): F[MailData] = {
        val tpl = cfg.templates.alias
        val td  = TemplateData(acc.userLogin, baseUrl / aliasId.id, false, "")
        MailData(td.render(tpl.subject), td.render(tpl.body)).pure[F]
      }

      def sendMail(
          acc: AccountId,
          receiver: List[MailAddress],
          mail: MailData
      ): F[MailSendResult] = {
        def recipients: EitherT[F, MailSendResult, List[MailAddress]] =
          if (receiver.isEmpty) EitherT.leftT(MailSendResult.noRecipients)
          else EitherT.rightT(receiver)

        def sender: EitherT[F, MailSendResult, MailAddress] =
          cfg.smtp.defaultFrom match {
            case Some(from) => EitherT.rightT(from)
            case None =>
              EitherT(store.transact(Queries.getEmail(acc.id)).map {
                case Some(f) => Right(f)
                case None    => Left(MailSendResult.NoSender)
              })
          }

        def createMail(rec: List[MailAddress], sender: MailAddress): Mail[F] =
          MailBuilder.build(
            From(sender),
            Subject(mail.subject),
            TextBody[F](mail.body),
            ListId(cfg.smtp.listId),
            Tos(rec)
          )

        def send(mail: Mail[F]): F[MailSendResult] =
          emil(cfg.toEmil).send(mail).attempt.map {
            case Right(_) => MailSendResult.success
            case Left(ex) => MailSendResult.sendFailure(ex)
          }

        val res = for {
          recs <- recipients
          from <- (sender: EitherT[F, MailSendResult, MailAddress])
        } yield createMail(recs, from)

        if (!cfg.enabled) MailSendResult.featureDisabled.pure[F]
        else res.foldF(r => r.pure[F], mail => send(mail))
      }

    })

  case class Tos[F[_]](ma: List[MailAddress]) extends Trans[F] {
    def apply(mail: Mail[F]): Mail[F] =
      mail.mapMailHeader(_.mapRecipients(rec => ma.foldLeft(rec)(_.addTo(_))))
  }

  case class ListId[F[_]](listId: String) extends Trans[F] {
    def apply(mail: Mail[F]): Mail[F] =
      if (listId.trim.isEmpty) mail
      else CustomHeader("List-Id", s"<$listId>").apply(mail)
  }
}
