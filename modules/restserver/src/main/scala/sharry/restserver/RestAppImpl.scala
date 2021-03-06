package sharry.restserver

import scala.concurrent.ExecutionContext

import cats.effect._
import cats.implicits._

import sharry.backend.BackendApp

final class RestAppImpl[F[_]: Sync](val config: Config, val backend: BackendApp[F])
    extends RestApp[F] {

  def init: F[Unit] =
    Sync[F].pure(())

  def shutdown: F[Unit] =
    ().pure[F]

}

object RestAppImpl {

  def create[F[_]: Async](
      cfg: Config,
      connectEC: ExecutionContext
  ): Resource[F, RestApp[F]] =
    for {
      backend <- BackendApp(cfg.backend, connectEC)
      app = new RestAppImpl[F](cfg, backend)
      appR <- Resource.make(app.init.map(_ => app))(_.shutdown)
    } yield appR

}
