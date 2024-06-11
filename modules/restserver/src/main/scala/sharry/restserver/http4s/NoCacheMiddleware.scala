package sharry.restserver.http4s

import cats.Functor
import cats.data.Kleisli
import cats.data.NonEmptyList

import sharry.common.*

import org.http4s.*
import org.http4s.headers.*

object NoCacheMiddleware {
  private val noCacheHeader =
    `Cache-Control`(
      NonEmptyList.of(
        CacheDirective.`max-age`(Duration.zero.toScala),
        CacheDirective.`no-store`
      )
    )

  def apply[F[_]: Functor, G[_], A](
      noCache: Boolean
  )(in: Kleisli[F, A, Response[F]]): Kleisli[F, A, Response[F]] =
    if (noCache) in.map(_.putHeaders(noCacheHeader))
    else in

  def route[F[_]: Functor](noCache: Boolean)(in: HttpRoutes[F]): HttpRoutes[F] =
    if (noCache) in.map(_.putHeaders(noCacheHeader))
    else in
}
