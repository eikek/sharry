package sharry.restserver

import cats.implicits._
import cats.effect._
import sharry.backend.BackendApp

import scala.concurrent.ExecutionContext

final class RestAppImpl[F[_]: Sync](val config: Config, val backend: BackendApp[F])
    extends RestApp[F] {

  def init: F[Unit] =
    Sync[F].pure(())

  def shutdown: F[Unit] =
    ().pure[F]

}

object RestAppImpl {

  def create[F[_]: ConcurrentEffect: ContextShift: Timer](
      cfg: Config,
      connectEC: ExecutionContext,
      blocker: Blocker
  ): Resource[F, RestApp[F]] =
    for {
      backend <- BackendApp(cfg.backend, connectEC, blocker)
      app     = new RestAppImpl[F](cfg, backend)
      appR    <- Resource.make(app.init.map(_ => app))(_.shutdown)
    } yield appR

}
