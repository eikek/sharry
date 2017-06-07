package sharry.server.routes

import java.time.Duration
import shapeless.{::, HNil}
import fs2.{Stream, Task}
import cats.syntax.either._
import spinoco.fs2.http.routing._

import sharry.store.data._
import sharry.server.paths
import sharry.server.config._
import sharry.store.upload.UploadStore
import sharry.server.routes.syntax._
import sharry.server.jsoncodec._

object alias {

  def endpoint(auth: AuthConfig, uploadCfg: UploadConfig, store: UploadStore) =
    choice2(updateAlias(auth, uploadCfg, store)
      , createAlias(auth, uploadCfg, store)
      , getAlias(store)
      , listAliases(auth, store)
      , deleteAlias(auth, store))

  def updateAlias(authCfg: AuthConfig, cfg: UploadConfig, store: UploadStore): Route[Task] =
    Post >> paths.aliases.matcher /"update" >> authz.user(authCfg) :: jsonBody[AliasUpdate] map {
      case login :: alias :: HNil =>
        val a = Alias.generate(login, alias.name, Duration.ZERO).
          copy(id = alias.id).
          copy(enable = alias.enable)
        UploadCreate.parseValidity(alias.validity).
          flatMap({ given =>
            if (cfg.maxValidity.compareTo(given) >= 0) Right(given)
            else Left("Validity time is too long.")
          }).
          map(v => a.copy(validity = v)).
          map(a => store.updateAlias(a).
            map({ n => if (n == 0) NotFound.body("0") else Ok.body(n.toString) })).
          valueOr(msg => Stream.emit(BadRequest.message(msg)))
    }

  def createAlias(authCfg: AuthConfig, cfg: UploadConfig, store: UploadStore): Route[Task] =
    Post >> paths.aliases.matcher >> authz.user(authCfg) map { (login: String) =>
      val alias = Alias.generate(login, "New alias", min(Duration.ofDays(5), cfg.maxValidity))
      store.createAlias(alias).
        map(_ => Ok.body(alias))
    }

  private def min(d1: Duration, d2: Duration) =
    if (d1.compareTo(d2) < 0) d1 else d2

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
