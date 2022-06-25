package sharry.restserver

import scala.concurrent.ExecutionContext

import cats.effect._
import cats.implicits._

import sharry.backend.BackendApp
import sharry.restserver.config.Config

final class RestAppImpl[F[_]: Sync](val config: Config, val backend: BackendApp[F])
    extends RestApp[F] {

  def init: Resource[F, Unit] =
    for {
      _ <- backend.files.computeBackgroundChecksum.void
      cf = config.backend.files.copyFiles
      _ <-
        if (cf.enable)
          Resource.eval(backend.files.copyFiles(cf.source, cf.target))
        else Resource.pure[F, Int](0)
    } yield ()

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
      appR <- app.init.onFinalize(app.shutdown).as(app)
    } yield appR
}
