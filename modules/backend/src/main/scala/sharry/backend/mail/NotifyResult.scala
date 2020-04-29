package sharry.backend.mail

sealed trait NotifyResult {}

object NotifyResult {
  def missingEmail: NotifyResult    = MissingEmail
  def featureDisabled: NotifyResult = FeatureDisabled

  case object InvalidAlias extends NotifyResult

  case object FeatureDisabled extends NotifyResult

  case object MissingEmail extends NotifyResult

  case class SendFailed(err: String) extends NotifyResult

  case object SendSuccessful extends NotifyResult

}
