package sharry.restserver.config

import cats.effect.*

object ConfigFile {

  def loadConfig: IO[Config] =
    ConfigValues.fullConfig.load[IO]

}
