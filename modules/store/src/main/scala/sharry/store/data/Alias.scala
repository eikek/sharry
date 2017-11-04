package sharry.store.data

import java.time.Instant
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

  implicit val _aliasDecoder: Decoder[Alias] = deriveDecoder[Alias]
  implicit val _aliasEncoder: Encoder[Alias] = deriveEncoder[Alias]

}
