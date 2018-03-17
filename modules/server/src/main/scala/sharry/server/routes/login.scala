package sharry.server.routes

import java.time.Instant

import scodec.bits.ByteVector
import cats.syntax.either._
import fs2.Stream
import cats.effect.IO
import spinoco.protocol.http.header.value.HttpCookie
import spinoco.protocol.http.header.`Set-Cookie`
import spinoco.fs2.http.routing._
import spinoco.fs2.http.HttpResponse

import sharry.common.duration._
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

  def byPass(auth: Authenticate): Matcher[IO, Stream[IO, AuthResult]] =
    paths.authLogin >> jsonBody[UserPass] map { (up: UserPass) =>
      auth.authc(up.login, up.pass)
    }

  def byCookie(auth: Authenticate): Matcher[IO, Stream[IO, AuthResult]] =
    paths.authCookie >> sharryCookie map { (token: Token) =>
      auth.authc(token, Instant.now)
    }

  def sharryCookie: Matcher[IO, Token] =
    cookie(cookieName).map { (c: HttpCookie) =>
      Token.parse(c.content)
    }


  def doLogin(e: Matcher[IO, Stream[IO,AuthResult]], domain: String, cfg: AuthConfig): Route[IO] = {
    def makeResponse(ar: AuthResult): HttpResponse[IO] = ar.
      map(acc => Ok.body(acc.noPass).withHeader(`Set-Cookie`(makeCookie(acc, domain, cfg.maxCookieLifetime, cfg.appKey)))).
      valueOr(err => Unauthorized.message(err))

    Post >> e map { (s: Stream[IO,AuthResult]) =>
      s.map(makeResponse)
    }
  }

  def removeCookie(domain: String): Route[IO] =
    Get >> paths.logout.matcher map { _ =>
      val c = makeCookie(Token.invalid, domain).copy(maxAge = Some(0.seconds.asScala))
      Stream.emit(Ok.noBody.withHeader(`Set-Cookie`(c)))
    }

  def makeCookie(t: Token, domain: String): HttpCookie = {
    HttpCookie(name = cookieName
      , content =  t.asString
      , httpOnly = true
      , maxAge = Some(Duration.between(Instant.now, t.ends).asScala)
      , path = Some(paths.api1.path)
      , domain = Some(domain)
      , params = Map.empty
      , expires = None
      , secure = false
    )
  }

  def makeCookie(a: Account, domain: String, cookieAge: Duration, appKey: ByteVector): HttpCookie =
    makeCookie(Token(a.login, Instant.now.plus(cookieAge.asJava), appKey), domain)

  val cookieName = "sharry_auth"
}
