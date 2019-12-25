package sharry.common

import io.circe.Decoder
import io.circe.Encoder

sealed trait AccountSource {

  def name: String

}

object AccountSource {

  case object Intern extends AccountSource {
    val name = "intern"
  }
  case object Extern extends AccountSource {
    val name = "extern"
  }
  case class OAuth(context: String) extends AccountSource {
    val name = s"oauth:$context"
  }

  def parse(str: String): Either[String, AccountSource] =
    str.toLowerCase match {
      case "intern"                    => Right(Intern)
      case "extern"                    => Right(Extern)
      case s if s.startsWith("oauth:") => Right(OAuth(s.substring(6)))
      case _                           => Left(s"Invalid account source: $str")
    }

  def unsafe(str: String): AccountSource =
    parse(str).fold(sys.error, identity)

  def intern: AccountSource                 = Intern
  def extern: AccountSource                 = Extern
  def oauth(context: String): AccountSource = OAuth(context)

  implicit val jsonDecoder: Decoder[AccountSource] =
    Decoder.decodeString.emap(parse)
  implicit val jsonEncoder: Encoder[AccountSource] =
    Encoder.encodeString.contramap(_.name)
}
