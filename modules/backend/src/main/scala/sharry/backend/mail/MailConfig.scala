package sharry.backend.mail

import sharry.common.*

import emil.{MailConfig as EmilConfig, *}
import yamusca.imports.*

case class MailConfig(
    enabled: Boolean,
    smtp: MailConfig.Smtp,
    templates: MailConfig.Templates
) {

  def toEmil: EmilConfig =
    EmilConfig(
      url = s"smtp://${smtp.host}:${smtp.port}",
      user = smtp.user,
      password = smtp.password.pass,
      sslType = smtp.sslType,
      enableXOAuth2 = false,
      disableCertificateCheck = !smtp.checkCertificates,
      timeout = smtp.timeout.toScala
    )
}

object MailConfig {

  case class Smtp(
      host: String,
      port: Int,
      user: String,
      password: Password,
      sslType: SSLType,
      checkCertificates: Boolean,
      timeout: Duration,
      defaultFrom: Option[MailAddress],
      listId: String
  )

  case class Templates(download: MailTpl, alias: MailTpl, uploadNotify: MailTpl)

  case class MailTpl(subject: Template, body: Template)
}
