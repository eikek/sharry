package sharry.restserver

import sharry.backend.BackendApp
import sharry.restserver.config.Config

trait RestApp[F[_]] {

  def config: Config

  def init: F[Unit]

  def backend: BackendApp[F]
}
