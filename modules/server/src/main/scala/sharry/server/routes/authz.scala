package sharry.server.routes

import java.time.Instant

import cats.effect.IO
import spinoco.fs2.http.routing._
import spinoco.protocol.http._

import sharry.common.data.Account
import sharry.store.data.Alias
import sharry.store.upload.UploadStore
import sharry.server.authc._
import sharry.server.config._
import sharry.server.routes.syntax._

object authz {
  val aliasHeaderName = "X-Sharry-Alias"

  def user(cfg: AuthConfig): Matcher[IO, String] =
    if (!cfg.enable) Matcher.success(cfg.defaultUser)
    else login.sharryCookie.flatMap {
      case token if token.verify(Instant.now, cfg.appKey) =>
        Matcher.success(token.login)
      case _ =>
        Matcher.respond(Unauthorized.message("Not authenticated"))
    }

  def admin(auth: Authenticate): Matcher[IO, Account] =
    login.sharryCookie.
      evalMap(token => auth.authc(token, Instant.now).compile.last).
      flatMap {
        case Some(Right(account)) =>
          if (account.admin) Matcher.success(account)
          else Matcher.respond(Forbidden.message("Not authorized for admin actions"))
        case Some(Left(err)) =>
          Matcher.respond(Unauthorized.message("Not authenticated."))
        case None =>
          Matcher.respondWith(HttpStatusCode.InternalServerError)
      }

  def userId(cfg: AuthConfig, store: UploadStore): Matcher[IO, UserId] =
    // if alias page is used, it is preferred even if the user is logged in currently
    alias(store).map(UserId.apply) or user(cfg).map(UserId.apply)


  def alias(store: UploadStore): Matcher[IO, Alias] = {
    syntax.aliasId.
      evalMap(id => store.getActiveAlias(id).compile.last).
      flatMap {
        case Some(alias) => Matcher.success(alias)
        case None => Matcher.respondWith(HttpStatusCode.Forbidden)
      }
  }
}
