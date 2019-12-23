package sharry.restserver

import sharry.backend.BackendApp

trait RestApp[F[_]] {

  def config: Config

  def init: F[Unit]

  def backend: BackendApp[F]
}
