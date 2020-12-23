package sharry.common

import io.circe.{Decoder, Encoder}

final class CIIdent private (val value: Ident) extends AnyVal {}

object CIIdent {

  def unsafe(str: String): CIIdent =
    apply(Ident.unsafe(str))

  def apply(s: Ident): CIIdent =
    new CIIdent(Ident.unsafe(s.id.toLowerCase))

  implicit val jsonEncoder: Encoder[CIIdent] =
    Ident.encodeIdent.contramap(_.value)

  implicit val jsonDecoder: Decoder[CIIdent] =
    Ident.decodeIdent.map(CIIdent.apply)
}
