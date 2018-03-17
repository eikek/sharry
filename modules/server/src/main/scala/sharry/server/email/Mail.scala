package sharry.server.email

import cats.effect.IO
import cats._
import cats.implicits._

import Header._

case class Mail(header: List[Header], body: Body) {
  def withTo(m: Address): Mail =
    withHeader(To(m))
  def addTo(m: Address): Mail =
    copy(header = To(m) :: header)
  def withSubject(line: String): Mail =
    withHeader(Subject(line))

  def recipients: List[Address] = header.
    collect({ case To(a) => a })

  def singleRecipient: String =
    recipients.headOption.map(_.mail.toString) getOrElse ""

  /** Replace all same named headers with `h` */
  def withHeader(h: Header): Mail = {
    val newHeader = (h :: header).
      map(e => if (h.name == e.name) h else e).
      groupBy(_.name).
      map(_._2.head).
      toList
    copy(header = newHeader)
  }

  def withTextBody(text: String): Mail =
    copy(body = text)
}

object Mail {

  def apply(to: String, subject: String, text: String): IO[Mail] =
    for {
      t <- Address.parse(to)
    } yield Mail(List(To(t), Subject(subject)), text)

  def apply(to: List[String], subject: String, text: String): IO[Mail] =
    for {
      t <- Traverse[List].traverse(to)(Address.parse)
    } yield Mail(Subject(subject) :: t.map(To.apply).toList, text)

}
