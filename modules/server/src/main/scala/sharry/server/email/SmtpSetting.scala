package sharry.server.email

import org.xbill.DNS._
import fs2.Task

case class SmtpSetting(
  host: String,
  port: Int,
  user: String,
  password: String,
  from: String,
  startTls: Boolean,
  ssl: Boolean
) {

  def hidePass = copy(password = if (password.isEmpty) "<no-pass>" else "***")
}


object SmtpSetting {
  def fromAddress(m: Address): Task[Option[SmtpSetting]] =
    findMx(m.domain).or(Task.now(Nil)).
      map(_.headOption).
      map(_.map(fromMx))

  def fromMx(host: String): SmtpSetting =
    SmtpSetting(host, 0, "", "", "", false, false)

  private def findMx(domain: String): Task[List[String]] = Task.delay {
    val records = new Lookup(domain, Type.MX).run()
      .map(_.asInstanceOf[MXRecord]).toList.sortBy(_.getPriority)

    records.map(_.getTarget.toString.stripSuffix("."))
  }
}
