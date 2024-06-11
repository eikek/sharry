package sharry.restserver.routes

import cats.data.OptionT
import cats.effect.*
import cats.implicits.*

import sharry.backend.BackendApp
import sharry.backend.auth.AuthToken
import sharry.backend.share.*
import sharry.common.*
import sharry.restapi.model.*
import sharry.restserver.config.Config
import sharry.restserver.routes.headers.SharryPassword
import sharry.store.AddResult

import org.http4s.*
import org.http4s.circe.CirceEntityDecoder.*
import org.http4s.circe.CirceEntityEncoder.*
import org.http4s.dsl.Http4sDsl

object ShareRoutes {

  def apply[F[_]: Async](
      backend: BackendApp[F],
      token: AuthToken,
      cfg: Config
  ): HttpRoutes[F] = {
    val logger = sharry.logging.getLogger[F]
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of[F] {
      case req @ GET -> Root / "search" =>
        val q = req.params.getOrElse("q", "")
        for {
          _ <- logger.trace(s"Listing shares: $q")
          now <- Timestamp.current[F]
          all <- backend.share.findShares(q, token.account).take(100).compile.toVector
          list = ShareList(all.map(shareListItem(now)).toList)
          resp <- Ok(list)
        } yield resp

      case req @ GET -> Root / Ident(id) =>
        val pw = SharryPassword(req)
        ShareDetailResponse(
          dsl,
          req,
          backend,
          cfg,
          ShareId.secured(id, token.account),
          pw
        )

      case req @ POST -> Root / Ident(id) / "publish" =>
        (for {
          in <- OptionT.liftF(req.as[PublishData])
          res <-
            backend.share
              .publish(id, token.account, in.reuseId)
              .attempt
              .map(AddResult.fromEither)
          resp <- OptionT.liftF(Ok(Conv.basicResult(res, "Share published.")))
        } yield resp).getOrElseF(NotFound())

      case DELETE -> Root / Ident(id) / "publish" =>
        (for {
          res <-
            backend.share.unpublish(id, token.account).attempt.map(AddResult.fromEither)
          resp <- OptionT.liftF(Ok(Conv.basicResult(res, "Share unpublished.")))
        } yield resp).getOrElseF(NotFound())

      case req @ GET -> Root / Ident(id) / "file" / Ident(fid) =>
        val pw = SharryPassword(req)
        val chunkSize = cfg.fileDownload.downloadChunkSize
        ByteResponse(
          dsl,
          req,
          backend,
          ShareId.secured(id, token.account),
          pw,
          chunkSize,
          fid
        )

      case req @ HEAD -> Root / Ident(id) / "file" / Ident(fid) =>
        val pw = SharryPassword(req)
        val chunkSize = cfg.fileDownload.downloadChunkSize
        ByteResponse(
          dsl,
          req,
          backend,
          ShareId.secured(id, token.account),
          pw,
          chunkSize,
          fid
        )

      // make it safer by also using the share id
      case DELETE -> Root / Ident(_) / "file" / Ident(fid) =>
        (for {
          e <-
            backend.share.deleteFile(token.account, fid).attempt.map(AddResult.fromEither)
          resp <- OptionT.liftF(Ok(Conv.basicResult(e, "File deleted.")))
        } yield resp).getOrElseF(NotFound())

      case DELETE -> Root / Ident(id) =>
        (for {
          e <-
            backend.share.deleteShare(token.account, id).attempt.map(AddResult.fromEither)
          resp <- OptionT.liftF(Ok(Conv.basicResult(e, "Share deleted.")))
        } yield resp).getOrElseF(NotFound())

      case req @ POST -> Root / Ident(id) / "description" =>
        (for {
          in <- OptionT.liftF(req.as[SingleString])
          res <-
            backend.share
              .setDescription(token.account, id, in.value)
              .attempt
              .map(AddResult.fromEither)
          resp <- OptionT.liftF(Ok(Conv.basicResult(res, "Description updated.")))
        } yield resp).getOrElseF(NotFound())

      case req @ POST -> Root / Ident(id) / "name" =>
        (for {
          in <- OptionT.liftF(req.as[SingleString])
          res <-
            backend.share
              .setName(token.account, id, Some(in.value))
              .attempt
              .map(AddResult.fromEither)
          resp <- OptionT.liftF(Ok(Conv.basicResult(res, "Name updated.")))
        } yield resp).getOrElseF(NotFound())

      case DELETE -> Root / Ident(id) / "name" =>
        (for {
          res <-
            backend.share
              .setName(token.account, id, None)
              .attempt
              .map(AddResult.fromEither)
          resp <- OptionT.liftF(Ok(Conv.basicResult(res, "Name deleted.")))
        } yield resp).getOrElseF(NotFound())

      case req @ POST -> Root / Ident(id) / "validity" =>
        (for {
          in <- OptionT.liftF(req.as[SingleNumber])
          res <-
            backend.share
              .setValidity(token.account, id, Duration.millis(in.value))
              .attempt
              .map(AddResult.fromEither)
          resp <- OptionT.liftF(Ok(Conv.basicResult(res, "Validity updated.")))
        } yield resp).getOrElseF(NotFound())

      case req @ POST -> Root / Ident(id) / "maxviews" =>
        (for {
          in <- OptionT.liftF(req.as[SingleNumber])
          res <-
            backend.share
              .setMaxViews(token.account, id, in.value.toInt)
              .attempt
              .map(AddResult.fromEither)
          resp <- OptionT.liftF(Ok(Conv.basicResult(res, "Max. views updated.")))
        } yield resp).getOrElseF(NotFound())

      case req @ POST -> Root / Ident(id) / "password" =>
        (for {
          in <- OptionT.liftF(req.as[SingleString])
          res <-
            backend.share
              .setPassword(token.account, id, Some(Password(in.value)))
              .attempt
              .map(AddResult.fromEither)
          resp <- OptionT.liftF(Ok(Conv.basicResult(res, "Password updated.")))
        } yield resp).getOrElseF(NotFound())

      case DELETE -> Root / Ident(id) / "password" =>
        (for {
          res <-
            backend.share
              .setPassword(token.account, id, None)
              .attempt
              .map(AddResult.fromEither)
          resp <- OptionT.liftF(Ok(Conv.basicResult(res, "Password deleted.")))
        } yield resp).getOrElseF(NotFound())
    }
  }

  def shareListItem(now: Timestamp)(item: ShareItem): ShareListItem =
    ShareListItem(
      item.share.id,
      item.share.name,
      item.alias.map(a => AliasIdName(a.id, a.name)),
      item.share.validity,
      item.share.maxViews,
      item.share.password.isDefined,
      item.share.created,
      item.files.count,
      item.files.size,
      item.published.filter(_.enabled).map(ps => ps.publishUntil.isAfter(now))
    )
}
