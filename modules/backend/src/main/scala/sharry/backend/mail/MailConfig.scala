package sharry.backend.mail

import emil.{MailConfig => EmilConfig, _}
import yamusca.imports._

import sharry.common._

case class MailConfig(
    enabled: Boolean,
    smtp: MailConfig.Smtp,
    templates: MailConfig.Templates
) {

  def toEmil: EmilConfig =
    EmilConfig(
      s"smtp://${smtp.host}:${smtp.port}",
      smtp.user,
      smtp.password.pass,
      smtp.sslType,
      !smtp.checkCertificates,
      smtp.timeout.toScala
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
