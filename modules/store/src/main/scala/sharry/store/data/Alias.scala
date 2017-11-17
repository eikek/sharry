package sharry.store.data

import java.time.Instant
import cats.data.Validated
import io.circe._, io.circe.generic.semiauto._
import sharry.common.JsonCodec
import sharry.common.rng._
import sharry.common.duration._

case class Alias(
  id: String
    ,login: String
    ,name: String
    ,validity: Duration
    ,created: Instant
    ,enable: Boolean
)

object Alias {
  import JsonCodec._

  def generate(login: String, name: String, validity: Duration): Alias =
    Alias(Gen.ident(16,24).generate(), login, name, validity, Instant.now, true)

  def validateId(id: String): Validated[String, String] = {
    val chars = (('a' to 'z') ++ ('A' to 'Z') ++ ('0' to '9') ++ "_-").toSet
    if (id.forall(chars.contains)) Validated.valid(id)
    else Validated.invalid(s"Not an alphanumeric identifier: $id")
  }

  implicit val _aliasDecoder: Decoder[Alias] = deriveDecoder[Alias]
  implicit val _aliasEncoder: Encoder[Alias] = deriveEncoder[Alias]

}
