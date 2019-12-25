package sharry.restserver.routes

import cats.effect._
import org.http4s._
import org.http4s.dsl.Http4sDsl

import sharry.common._
import sharry.backend.BackendApp
import sharry.restserver.Config
import sharry.backend.share._
import sharry.restserver.routes.headers.SharryPassword

object OpenShareRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], cfg: Config): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of[F] {
      case req @ GET -> Root / Ident(id) =>
        val pw = SharryPassword(req)
        ShareDetailResponse(dsl, backend, cfg, ShareId.publish(id), pw)

      case req @ GET -> Root / Ident(id) / file / Ident(fid) =>
        val pw = SharryPassword(req)
        ByteResponse(dsl, req, backend, ShareId.publish(id), pw, fid)

    }
  }

}
