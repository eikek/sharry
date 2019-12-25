package sharry.common

import io.circe._

sealed trait SignupMode { self: Product =>
  final def name: String =
    productPrefix.toLowerCase
}
object SignupMode {

  case object Open extends SignupMode

  case object Invite extends SignupMode

  case object Closed extends SignupMode

  def fromString(str: String): Either[String, SignupMode] =
    str.toLowerCase match {
      case "open"   => Right(Open)
      case "invite" => Right(Invite)
      case "closed" => Right(Closed)
      case _        => Left(s"Invalid signup mode: $str")
    }
  def unsafe(str: String): SignupMode =
    fromString(str).fold(sys.error, identity)

  def open: SignupMode   = Open
  def invite: SignupMode = Invite
  def closed: SignupMode = Closed

  implicit val jsonEncoder: Encoder[SignupMode] =
    Encoder.encodeString.contramap(_.name)
  implicit val jsonDecoder: Decoder[SignupMode] =
    Decoder.decodeString.emap(fromString)
}
