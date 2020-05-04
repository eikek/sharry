package sharry.restserver.routes

import cats.effect._
import cats.implicits._
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.dsl.Http4sDsl
import org.log4s.getLogger

import sharry.backend.BackendApp
import sharry.backend.auth.AuthToken
import sharry.restapi.model._
import sharry.restserver.Config
import sharry.common._
import sharry.common.syntax.all._
import sharry.store.records.RAlias
import cats.data.OptionT

object AliasRoutes {
  private[this] val logger = getLogger

  def apply[F[_]: Effect](
      backend: BackendApp[F],
      token: AuthToken,
      cfg: Config
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root =>
        for {
          in   <- req.as[AliasChange]
          _    <- logger.fdebug(s"Create new alias for ${token.account}")
          na   <- RAlias.createNew[F](token.account.id, in.name, in.validity, in.enabled)
          res  <- backend.alias.create(na)
          resp <- Ok(convert(Conv.basicResult(res, "Alias successfully created."), na.id))
        } yield resp

      case req @ GET -> Root =>
        val q = req.params.getOrElse("q", "")
        for {
          _    <- logger.ftrace(s"Listing aliases for ${token.account}")
          list <- backend.alias.findAll(token.account.id, q).take(100).compile.toVector
          resp <- Ok(AliasList(list.map(convert).toList))
        } yield resp

      case req @ POST -> Root / Ident(id) =>
        for {
          in <- req.as[AliasChange]
          _  <- logger.fdebug(s"Change alias $id to $in")
          na <- RAlias.createNew[F](token.account.id, in.name, in.validity, in.enabled)
          res <- backend.alias.modify(
            id,
            token.account.id,
            na.copy(id = in.id.getOrElse(na.id))
          )
          resp <- Ok(
            convert(
              Conv.basicResult(res, "Alias successfully modified."),
              in.id.getOrElse(na.id)
            )
          )
        } yield resp

      case GET -> Root / Ident(id) =>
        val opt = for {
          adb  <- OptionT(backend.alias.findById(id, token.account.id))
          resp <- OptionT.liftF(Ok(convert(adb)))
        } yield resp
        opt.getOrElseF(NotFound())

      case DELETE -> Root / Ident(id) =>
        for {
          res  <- backend.alias.delete(id, token.account.id)
          resp <- Ok(BasicResult(res, if (res) "Alias deleted." else "Alias not found"))
        } yield resp
    }
  }

  def convert(r: RAlias): AliasDetail =
    AliasDetail(r.id, r.name, r.validity, r.enabled, r.created)

  def convert(br: BasicResult, aliasId: Ident): IdResult =
    IdResult(br.success, br.message, aliasId)
}
