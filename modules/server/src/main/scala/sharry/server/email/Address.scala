package sharry.server.email

import javax.mail.internet.InternetAddress
import cats.effect.IO
import io.circe._

case class Address(mail: InternetAddress) {
  lazy val address = mail.getAddress
  lazy val personal = Option(mail.getPersonal)
  lazy val domain: String = {
    address.lastIndexOf('@') match {
      case -1 => ""
      case n => address.substring(n+1)
    }
  }
}

object Address {
  def parse(mail: String): IO[Address] = IO {
    val a = new InternetAddress(mail)
    a.validate
    Address(a)
  }

  implicit val _jsonEncoder: Encoder[Address] = Encoder.encodeString.contramap[Address](_.mail.toString)
}
