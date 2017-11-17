package sharry.server.routes

import shapeless.{::, HNil}
import fs2.{Stream, Task}
import cats.Order
import spinoco.fs2.http.routing._

import sharry.common.data._
import sharry.common.duration._
import sharry.common.streams
import sharry.store.data._
import sharry.server.paths
import sharry.server.config._
import sharry.store.upload.UploadStore
import sharry.server.routes.syntax._

object alias {

  def endpoint(auth: AuthConfig, uploadCfg: UploadConfig, store: UploadStore) =
    choice2(updateAlias(auth, uploadCfg, store)
      , createAlias(auth, uploadCfg, store)
      , getAlias(store)
      , listAliases(auth, store)
      , deleteAlias(auth, store))

  def updateAlias(authCfg: AuthConfig, cfg: UploadConfig, store: UploadStore): Route[Task] =
    Post >> paths.aliases.matcher / as[String] :: authz.user(authCfg) :: jsonBody[AliasUpdate] map {
      case aliasId :: login :: alias :: HNil =>
        val a = Alias.generate(login, alias.name, Duration.zero).
          copy(id = alias.id).
          copy(enable = alias.enable)
        Duration.parse(alias.validity).
          ensure("Validity time is too long.")(cfg.maxValidity >= _).
          map(v => a.copy(validity = v)).
          andThen(a => Alias.validateId(a.id).map(_ => a)).
          map(a => store.getAlias(a.id).
            filter(a => a.id != aliasId).
            map(_ => BadRequest.message(s"An alias with id '${a.id}' already exists.")).
            through(streams.ifEmpty(
              store.updateAlias(a, aliasId).
                map({ n => if (n == 0) NotFound.body("0") else Ok.body(a) })))).
          valueOr(msg => Stream.emit(BadRequest.message(msg)))
    }

  def createAlias(authCfg: AuthConfig, cfg: UploadConfig, store: UploadStore): Route[Task] =
    Post >> paths.aliases.matcher >> authz.user(authCfg) map { (login: String) =>
      val alias = Alias.generate(login, "New alias", Order[Duration].min(5.days, cfg.maxValidity))
      store.createAlias(alias).
        map(_ => Ok.body(alias))
    }

  def listAliases(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Get >> paths.aliases.matcher >> authz.user(authCfg) map { (login: String) =>
      Stream.eval(store.listAliases(login).runLog).
        map(Ok.body(_))
    }

  def getAlias(store: UploadStore): Route[Task] =
    Get >> paths.aliases.matcher / as[String] map { (id: String) =>
      store.getActiveAlias(id).
        map(Ok.body(_)).
        through(NotFound.whenEmpty)
    }

  def deleteAlias(authCfg: AuthConfig, store: UploadStore): Route[Task] =
    Delete >> paths.aliases.matcher / as[String] :: authz.user(authCfg) map {
      case id :: login :: HNil =>
        store.deleteAlias(id, login).
          map({ n => if (n == 0) NotFound.body("0") else Ok.body(n.toString) })
    }
}
