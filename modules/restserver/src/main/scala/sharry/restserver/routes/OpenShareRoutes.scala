package sharry.restserver.routes

import cats.effect._

import sharry.backend.BackendApp
import sharry.backend.share._
import sharry.common._
import sharry.restserver.config.Config
import sharry.restserver.routes.headers.SharryPassword

import org.http4s._
import org.http4s.dsl.Http4sDsl

object OpenShareRoutes {

  def apply[F[_]: Async](backend: BackendApp[F], cfg: Config): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of[F] {
      case req @ GET -> Root / Ident(id) =>
        val pw = SharryPassword(req)
        ShareDetailResponse(dsl, req, backend, cfg, ShareId.publish(id), pw)

      case req @ GET -> Root / Ident(id) / "file" / Ident(fid) =>
        val pw = SharryPassword(req)
        val chunkSize = cfg.backend.files.downloadChunkSize
        ByteResponse(dsl, req, backend, ShareId.publish(id), pw, chunkSize, fid)

      case req @ HEAD -> Root / Ident(id) / "file" / Ident(fid) =>
        val pw = SharryPassword(req)
        val chunkSize = cfg.backend.files.downloadChunkSize
        ByteResponse(dsl, req, backend, ShareId.publish(id), pw, chunkSize, fid)
    }
  }
}
