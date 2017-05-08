package sharry.store.data

import java.time.{Duration, Instant}
import sharry.store.data.rng._

case class Alias(
  id: String
    ,login: String
    ,name: String
    ,validity: Duration
    ,created: Instant
    ,enable: Boolean
)

object Alias {

  def generate(login: String, name: String): Alias =
    Alias(Gen.ident(16,24).generate(), login, name, Duration.ofDays(5), Instant.now, true)
}
