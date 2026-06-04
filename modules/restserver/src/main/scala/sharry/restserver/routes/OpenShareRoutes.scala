package sharry.restserver.routes

import cats.data.OptionT
import cats.effect.*
import cats.implicits.*

import sharry.backend.BackendApp
import sharry.backend.share.*
import sharry.common.*
import sharry.restserver.config.Config
import sharry.restserver.routes.headers.SharryPassword

import org.http4s.*
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.*
import org.typelevel.ci.CIString

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
        val chunkSize = cfg.fileDownload.downloadChunkSize
        ByteResponse(dsl, req, backend, ShareId.publish(id), pw, chunkSize, fid)

      case req @ HEAD -> Root / Ident(id) / "file" / Ident(fid) =>
        val pw = SharryPassword(req)
        val chunkSize = cfg.fileDownload.downloadChunkSize
        ByteResponse(dsl, req, backend, ShareId.publish(id), pw, chunkSize, fid)

      case req @ GET -> Root / Ident(id) / "zip" =>
        (for {
          stream <- backend.share.loadZip(ShareId.publish(id))
          resp <- OptionT.liftF(
            Ok(stream).map(
              _.withHeaders(
                `Content-Type`(MediaType.application.zip),
                `Content-Disposition`(
                  "attachment",
                  Map(CIString("filename") -> s"$id.zip")
                )
              )
            )
          )
        } yield resp).getOrElseF(dsl.NotFound())
    }
  }
}
