package sharry.restserver.http4s

import cats.Functor

import sharry.common._

import org.http4s._

object EnvMiddleware {

  def apply[F[_]: Functor](in: HttpRoutes[F]): HttpRoutes[F] =
    NoCacheMiddleware.route(EnvMode.current.isDev)(in)
}
