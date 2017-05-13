package sharry.server.email

import javax.mail._
import com.typesafe.scalalogging.Logger
import shapeless.syntax.std.tuple._
import cats.data.ValidatedNel
import cats.data.Validated.{Valid,Invalid}
import fs2.{Stream, Task}
import fs2.util.Attempt

import Header._

object client {
  private val logger = Logger(getClass)

  def send_(setting: GetSetting)(mail: Mail): Stream[Task, Attempt[Mail]] = {
    splitMail(mail).
      evalMap(send1(setting))
  }

  def send(setting: GetSetting)(mail: Task[Mail]): Stream[Task, Attempt[Mail]] =
    Stream.eval(mail).flatMap(send_(setting))

  private def send1(setting: GetSetting)(mail: Mail): Task[Attempt[Mail]] = {
    val mimeMsg = extract1(mail).flatMap {
      case (to, subject, body, moreHeaders) =>
        for {
          smtp <- setting(to)
          sess <- makeSession(smtp)
          msg <- Task.delay {
            val msg = new internet.MimeMessage(sess)
            msg.setFrom(smtp.from)
            msg.setRecipient(Message.RecipientType.TO, to.mail)
            msg.setSubject(subject)
            msg.setText(body)
            moreHeaders.foreach { h =>
              msg.addHeader(h.name, h.value)
            }
            msg
          }
        } yield msg
    }

    mimeMsg.map(Transport.send).
      map(_ => mail).
      handleWith({ case ex =>
        logger.error(s"Error sending mail: $mail", ex)
        Task.fail(new Exception(mail.singleRecipient + ": "+ ex.getMessage))
      }).
      attempt
  }

  private def extract1(mail: Mail): Task[(Address, String, String, List[GenericHeader])] = {
    def validate[A](l: List[A], msg: String): ValidatedNel[String, A] = l match {
      case a :: Nil => Valid(a).toValidatedNel
      case Nil => Invalid(s"There is no $msg.").toValidatedNel
      case all => Invalid(s"There are more than one $msg: $all").toValidatedNel
    }

    val tos = validate(mail.header.collect({case To(a) => a}), "recipient")
    val subjects = validate(mail.header.collect({case Subject(line) => line}), "subject line")
    val text = Valid(mail.body).toValidatedNel
    val generic = mail.header.collect({case h: GenericHeader => h})

    tos.product(subjects).product(text) match {
      case Valid((t1, t)) => Task.now(t1 :+ t :+ generic)
      case Invalid(msgs) => Task.fail(new Exception(msgs.toList.mkString(", ")))
    }
  }

  private def makeSession(setting: SmtpSetting): Task[Session] = {
    val props = System.getProperties()
    if (setting.host.nonEmpty) {
      props.setProperty("mail.smtp.host", setting.host)
      if (setting.port > 0) {
        props.setProperty("mail.smtp.port", setting.port.toString)
      }
      if (setting.user.nonEmpty) {
        props.setProperty("mail.user", setting.user)
      }
      if (setting.password.nonEmpty) {
        props.setProperty("mail.password", setting.password)
      }
    }
    if (Option(props.getProperty("mail.smtp.host")).exists(_.nonEmpty))
      Task.now(Session.getInstance(props))
    else
      Task.fail(new Exception("no smtp host provided"))
  }

  private def splitMail(m: Mail): Stream[Task, Mail] = {
    Stream.emits(m.header.filter(_.name == To.name).
      map(to => m.withHeader(to)))
  }
}
