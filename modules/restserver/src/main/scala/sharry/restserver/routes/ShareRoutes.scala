package sharry.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import sharry.backend.BackendApp
import sharry.backend.auth.AuthToken
import sharry.backend.share._
import sharry.common._
import sharry.common.syntax.all._
import sharry.restapi.model._
import sharry.restserver.Config
import sharry.restserver.routes.headers.SharryPassword
import sharry.store.AddResult

import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.log4s._

object ShareRoutes {
  private[this] val logger = getLogger

  def apply[F[_]: Async](
      backend: BackendApp[F],
      token: AuthToken,
      cfg: Config
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of[F] {
      case req @ GET -> Root / "search" =>
        val q = req.params.getOrElse("q", "")
        for {
          _ <- logger.ftrace(s"Listing shares: $q")
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
        ByteResponse(dsl, req, backend, ShareId.secured(id, token.account), pw, fid)

      //make it safer by also using the share id
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
      item.share.password != None,
      item.share.created,
      item.files.count,
      item.files.size,
      item.published.filter(_.enabled).map(ps => ps.publishUntil.isAfter(now))
    )
}
