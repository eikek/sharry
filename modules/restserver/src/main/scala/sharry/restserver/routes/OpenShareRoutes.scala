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
import org.http4s.headers.`WWW-Authenticate`
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
        val pw = SharryPassword(req)
        val shareId = ShareId.publish(id)
        val authChallenge = `WWW-Authenticate`(Challenge("sharry", "sharry"))
        (for {
          result <- backend.share.loadZip(shareId, pw)
          resp <- OptionT.liftF(
            result.fold(
              stream =>
                Ok(stream).map(
                  _.withHeaders(
                    `Content-Type`(MediaType.application.zip),
                    `Content-Disposition`(
                      "attachment",
                      Map(CIString("filename") -> s"$id.zip")
                    )
                  )
                ),
              _ => dsl.Forbidden(),
              _ => dsl.Unauthorized(authChallenge)
            )
          )
        } yield resp).getOrElseF(dsl.NotFound())
    }
  }
}
