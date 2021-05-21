package sharry.backend.mail

import emil.MailAddress

sealed trait NotifyResult {
  def isSuccess: Boolean
  def isError: Boolean =
    !isSuccess

  def receiver: Option[MailAddress]
}

object NotifyResult {
  def featureDisabled: NotifyResult = FeatureDisabled

  case object InvalidAlias extends NotifyResult {
    val isSuccess                     = false
    def receiver: Option[MailAddress] = None
  }

  case object FeatureDisabled extends NotifyResult {
    val isSuccess                     = false
    def receiver: Option[MailAddress] = None
  }

  case class SendFailed(mail: MailAddress, err: String) extends NotifyResult {
    val isSuccess                     = false
    def receiver: Option[MailAddress] = Some(mail)
  }

  case class SendSuccessful(mail: MailAddress) extends NotifyResult {
    val isSuccess                     = true
    def receiver: Option[MailAddress] = Some(mail)
  }

}
