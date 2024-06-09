package sharry.restserver.http4s

import cats.Functor

import sharry.common.*

import org.http4s.*

object EnvMiddleware {

  def apply[F[_]: Functor](in: HttpRoutes[F]): HttpRoutes[F] =
    NoCacheMiddleware.route(EnvMode.current.isDev)(in)
}
