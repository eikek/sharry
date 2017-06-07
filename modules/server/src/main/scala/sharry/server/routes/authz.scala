package sharry.server.routes

import java.time.Instant

import fs2.Task
import spinoco.fs2.http.routing._
import spinoco.protocol.http._

import sharry.store.data.{Alias, Account}
import sharry.store.upload.UploadStore
import sharry.server.authc._
import sharry.server.config._
import sharry.server.routes.syntax._

object authz {
  val aliasHeaderName = "X-Sharry-Alias"

  def user(cfg: AuthConfig): Matcher[Task, String] =
    if (!cfg.enable) Matcher.success(cfg.defaultUser)
    else login.sharryCookie.flatMap {
      case token if token.verify(Instant.now, cfg.appKey) =>
        Matcher.success(token.login)
      case _ =>
        Matcher.respond(Unauthorized.message("Not authenticated"))
    }

  def admin(auth: Authenticate): Matcher[Task, Account] =
    login.sharryCookie.
      evalMap(token => auth.authc(token, Instant.now).runLast).
      flatMap {
        case Some(Right(account)) =>
          if (account.admin) Matcher.success(account)
          else Matcher.respond(Forbidden.message("Not authorized for admin actions"))
        case Some(Left(err)) =>
          Matcher.respond(Unauthorized.message("Not authenticated."))
        case None =>
          Matcher.respondWith(HttpStatusCode.InternalServerError)
      }

  def userId(cfg: AuthConfig, store: UploadStore): Matcher[Task, UserId] =
    // if alias page is used, it is preferred even if the user is logged in currently
    alias(store).map(UserId.apply) or user(cfg).map(UserId.apply)


  def alias(store: UploadStore): Matcher[Task, Alias] = {
    syntax.aliasId.
      evalMap(id => store.getActiveAlias(id).runLast).
      flatMap {
        case Some(alias) => Matcher.success(alias)
        case None => Matcher.respondWith(HttpStatusCode.Forbidden)
      }
  }
}
