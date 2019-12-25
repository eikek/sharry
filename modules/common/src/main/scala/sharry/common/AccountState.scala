package sharry.common

import io.circe._

sealed trait AccountState { self: Product =>
  final def name: String =
    productPrefix
}

object AccountState {
  val all = List(Active, Disabled)

  /** An active or enabled user. */
  case object Active extends AccountState

  /** The user is blocked by an admin. */
  case object Disabled extends AccountState

  def fromString(s: String): Either[String, AccountState] =
    s.toLowerCase match {
      case "active"   => Right(Active)
      case "disabled" => Right(Disabled)
      case _          => Left(s"Not a state value: $s")
    }

  def unsafe(str: String): AccountState =
    fromString(str).fold(sys.error, identity)

  def asString(s: AccountState): String = s.name

  implicit val accountStateEncoder: Encoder[AccountState] =
    Encoder.encodeString.contramap(AccountState.asString)

  implicit val accountStateDecoder: Decoder[AccountState] =
    Decoder.decodeString.emap(AccountState.fromString)

}
