package sharry.restserver

import sharry.backend.BackendApp
import sharry.restserver.config.Config

trait RestApp[F[_]] {

  def config: Config

  def backend: BackendApp[F]
}
