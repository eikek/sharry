package sharry.common

import java.security.SecureRandom
import java.util.UUID

import cats.effect.Sync

import io.circe.{Decoder, Encoder}
import scodec.bits.ByteVector

case class Ident(id: String) {

  def ++(other: Ident): Ident =
    new Ident(id + other.id)

  def isEmpty: Boolean =
    id.isEmpty

  def nonEmpty: Boolean =
    !isEmpty
}

object Ident {
  val atSign: Ident = new Ident("@")
  val empty: Ident = new Ident("")

  val chars: Set[Char] = (('A' to 'Z') ++ ('a' to 'z') ++ ('0' to '9') ++ "-_@.").toSet

  def randomUUID[F[_]: Sync]: F[Ident] =
    Sync[F].delay(unsafe(UUID.randomUUID.toString))

  def randomId[F[_]: Sync]: F[Ident] =
    Sync[F].delay {
      val random = new SecureRandom
      val buffer = new Array[Byte](32)
      random.nextBytes(buffer)
      unsafe(ByteVector.view(buffer).toBase58.grouped(11).mkString("-"))
    }

  def apply(str: String): Either[String, Ident] =
    fromString(str)

  def fromString(s: String): Either[String, Ident] =
    if (s.forall(chars.contains)) Right(new Ident(s))
    else Left(s"Invalid identifier: $s. Allowed chars: ${chars.mkString}")

  def fromBytes(bytes: ByteVector): Ident =
    unsafe(bytes.toBase58)

  def fromByteArray(bytes: Array[Byte]): Ident =
    fromBytes(ByteVector.view(bytes))

  def unsafe(s: String): Ident =
    fromString(s) match {
      case Right(id) => id
      case Left(err) => sys.error(err)
    }

  def unapply(arg: String): Option[Ident] =
    fromString(arg).toOption

  implicit val encodeIdent: Encoder[Ident] =
    Encoder.encodeString.contramap(_.id)

  implicit val decodeIdent: Decoder[Ident] =
    Decoder.decodeString.emap(Ident.fromString)

}
