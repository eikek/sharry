package sharry.backend.mail

sealed trait MailSendResult {}

object MailSendResult {

  def success: MailSendResult = Success
  def sendFailure(ex: Throwable): MailSendResult = SendFailure(ex)
  def noRecipients: MailSendResult = NoRecipients
  def noSender: MailSendResult = NoSender
  def featureDisabled: MailSendResult = FeatureDisabled

  case object Success extends MailSendResult

  case class SendFailure(ex: Throwable) extends MailSendResult

  case object NoRecipients extends MailSendResult

  case object NoSender extends MailSendResult

  case object FeatureDisabled extends MailSendResult
}
