package sharry.server.routes

import java.time.{Instant, Duration}

import scala.concurrent.duration._
import scodec.bits.ByteVector
import cats.syntax.either._
import fs2.{Stream, Task}
import spinoco.protocol.http.header.value.HttpCookie
import spinoco.protocol.http.header.`Set-Cookie`
import spinoco.fs2.http.routing._
import spinoco.fs2.http.HttpResponse

import sharry.common.data._
import sharry.server.config.{AuthConfig, WebConfig}
import sharry.server.paths
import sharry.server.authc._
import sharry.server.routes.syntax._

object login {

  def endpoint(auth: Authenticate, cfg: WebConfig, authCfg: AuthConfig) = {
    val domain = cfg.domain
    choice(doLogin(byPass(auth), domain, authCfg), doLogin(byCookie(auth), domain, authCfg), removeCookie(domain))
  }

  def byPass(auth: Authenticate): Matcher[Task, Stream[Task, AuthResult]] =
    paths.authLogin >> jsonBody[UserPass] map { (up: UserPass) =>
      auth.authc(up.login, up.pass)
    }

  def byCookie(auth: Authenticate): Matcher[Task, Stream[Task, AuthResult]] =
    paths.authCookie >> sharryCookie map { (token: Token) =>
      auth.authc(token, Instant.now)
    }

  def sharryCookie: Matcher[Task, Token] =
    cookie(cookieName).map { (c: HttpCookie) =>
      Token.parse(c.content)
    }


  def doLogin(e: Matcher[Task, Stream[Task,AuthResult]], domain: String, cfg: AuthConfig): Route[Task] = {
    def makeResponse(ar: AuthResult): HttpResponse[Task] = ar.
      map(acc => Ok.body(acc.noPass).withHeader(`Set-Cookie`(makeCookie(acc, domain, cfg.maxCookieLifetime, cfg.appKey)))).
      valueOr(err => Unauthorized.message(err))

    Post >> e map { (s: Stream[Task,AuthResult]) =>
      s.map(makeResponse)
    }
  }

  def removeCookie(domain: String): Route[Task] =
    Get >> paths.logout.matcher map { _ =>
      val c = makeCookie(Token.invalid, domain).copy(maxAge = Some(FiniteDuration(1, NANOSECONDS)))
      Stream.emit(Ok.noBody.withHeader(`Set-Cookie`(c)))
    }

  def makeCookie(t: Token, domain: String): HttpCookie = {
    HttpCookie(name = cookieName
      , content =  t.asString
      , httpOnly = true
      , maxAge = Some(FiniteDuration(Duration.between(Instant.now, t.ends).toNanos, NANOSECONDS))
      , path = Some(paths.api1.path)
      , domain = Some(domain)
      , params = Map.empty
      , expires = None
      , secure = false
    )
  }

  def makeCookie(a: Account, domain: String, cookieAge: Duration, appKey: ByteVector): HttpCookie =
    makeCookie(Token(a.login, Instant.now.plus(cookieAge), appKey), domain)

  val cookieName = "sharry_auth"
}
