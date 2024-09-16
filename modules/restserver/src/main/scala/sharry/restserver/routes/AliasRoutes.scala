package sharry.restserver.routes

import cats.data.OptionT
import cats.effect.*
import cats.implicits.*

import sharry.backend.BackendApp
import sharry.backend.alias.OAlias
import sharry.backend.auth.AuthToken
import sharry.common.*
import sharry.restapi.model.*
import sharry.restserver.config.Config
import sharry.store.records.RAlias

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder.*
import org.http4s.circe.CirceEntityEncoder.*
import org.http4s.dsl.Http4sDsl

object AliasRoutes {
  def apply[F[_]: Async](
      backend: BackendApp[F],
      token: AuthToken,
      cfg: Config
  ): HttpRoutes[F] = {
    val logger = sharry.logging.getLogger[F]
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root =>
        for {
          in <- req.as[AliasChange]
          _ <- logger.debug(s"Create new alias for ${token.account}")
          na <- RAlias.createNew[F](token.account.id, in.name, in.validity, in.enabled)
          data = OAlias.AliasInput(na, in.members)
          res <- backend.alias.create(data)
          resp <- Ok(convert(Conv.basicResult(res, "Alias successfully created."), na.id))
        } yield resp

      case req @ GET -> Root =>
        val q = req.params.getOrElse("q", "")
        for {
          _ <- logger.trace(s"Listing aliases for ${token.account}")
          list <- backend.alias
            .findAll(token.account.id, q)
            .take(cfg.maxPageSize)
            .compile
            .toVector
          resp <- Ok(AliasList(list.map(convert).toList))
        } yield resp

      case req @ POST -> Root / Ident(id) =>
        for {
          in <- req.as[AliasChange]
          _ <- logger.debug(s"Change alias $id to $in")
          na <- RAlias.createNew[F](token.account.id, in.name, in.validity, in.enabled)
          data = OAlias.AliasInput(na, in.members)
          res <- backend.alias.modify(
            id,
            token.account.id,
            data.copy(alias = data.alias.copy(id = in.id.getOrElse(na.id)))
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
          adb <- OptionT(backend.alias.findById(id, token.account.id))
          resp <- OptionT.liftF(Ok(convert(adb)))
        } yield resp
        opt.getOrElseF(NotFound())

      case DELETE -> Root / Ident(id) =>
        for {
          res <- backend.alias.delete(id, token.account.id)
          resp <- Ok(BasicResult(res, if (res) "Alias deleted." else "Alias not found"))
        } yield resp
    }
  }

  def convert(r: OAlias.AliasDetail): AliasDetail =
    AliasDetail(
      r.alias.id,
      r.alias.name,
      r.alias.validity,
      r.ownerLogin,
      r.alias.enabled,
      AccountLightList(r.members.map(m => AccountLight(m.accountId, m.login))),
      r.alias.created
    )

  def convert(br: BasicResult, aliasId: Ident): IdResult =
    IdResult(br.success, br.message, aliasId)
}
