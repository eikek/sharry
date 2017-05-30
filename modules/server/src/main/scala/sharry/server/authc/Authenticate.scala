package sharry.server.authc

import java.time.Instant
import org.log4s._
import fs2.{Stream, Task, Pipe}
import com.github.t3hnar.bcrypt._
import sharry.common.streams
import sharry.store.data.Account
import sharry.store.account.AccountStore
import sharry.server.config.AuthConfig

final class Authenticate(store: AccountStore, authConfig: AuthConfig, ext: ExternAuthc) {
  implicit private[this] val logger = getLogger

  def authc(login: String, pass: String): Stream[Task,AuthResult] = {
    if (authConfig.enable) {
      store.getAccount(login).
        through(streams.logEmpty(_.debug(s"No account found for login: $login"))).
        through(streams.logEach((a, l) => l.debug(s"Authenticating account ${a.noPass}"))).
        through(checkEnabled).
        through(verifyPresent(login, pass, ext)).
        through(verifyNewAccount(login, pass, ext)).
        through(logResult(login))
    } else {
      logger.warn(s"Authentication is disabled. Using default user ${authConfig.defaultUser}")
      store.getAccount(authConfig.defaultUser).
        through(checkEnabled).
        through(verifyPresent(login, pass, ExternAuthc.disabledAuth(authConfig))).
        through(verifyNewAccount(login, pass, ExternAuthc.disabledAuth(authConfig)))
    }
  }

  def logResult(login: String): Pipe[Task, AuthResult, AuthResult] =
    streams.logEach { (ar, logger) =>
      ar match {
        case Left(err) => logger.warn(s"Authentication failed for $login: $err")
        case Right(a) => logger.debug(s"Authentication successfull for ${a.noPass}")
      }
    }

  /** Authenticates a {{Token}} that is generated from an account. Thus
    * it fails if the account doesn't exist. */
  def authc(token: Token, now: Instant): Stream[Task, AuthResult] = {
    val fail = Stream.emit(AuthResult.failed).through(logResult(token.login))
    if (!token.verify(now, authConfig.appKey)) fail
    else store.getAccount(token.login).
      through(checkEnabled).
      through(streams.ifEmpty(fail)).
      through(logResult(token.login))
  }

  // if present check enabled
  def checkEnabled[F[_]]: Pipe[F, Account, AuthResult] =
    _.map { acc =>
      if (acc.enabled) AuthResult(acc) else AuthResult.fail("User account locked")
    }

  // if present, verify password internally or externally
  def verifyPresent(login: String, givenPass: String, ext: ExternAuthc): Pipe[Task, AuthResult, AuthResult] =
    _.flatMap {
      case Right(a @ Account.Internal(_, pass)) =>
        if (pass.exists(p => givenPass.isBcrypted(p))) Stream.emit(Right(a))
        else Stream.emit(AuthResult.failed)
      case Right(a @ Account.External(_)) =>
        streams.slogT(_.debug(s"Verify ${a.noPass} externally")) ++ ext.verify(login, givenPass).map {
          case Some(_) => AuthResult(a)
          case None => AuthResult.failed
        }
      case ar => Stream.emit(ar)
    }

  // if absent, verify via ext. if ok, create account; fail otherwise
  def verifyNewAccount(login: String, pass: String, ext: ExternAuthc): Pipe[Task, AuthResult, AuthResult] = {
    val create: Stream[Task,AuthResult] = streams.slogT(_.debug(s"Verify $login externally")) ++
      ext.verify(login, pass).flatMap {
        case Some(acc) =>
          streams.slogT(_.debug(s"Create new external account $acc")) ++
            store.createAccount(acc).map(_ => AuthResult(acc))
        case None =>
          Stream.emit(AuthResult.failed)
      }

    _.through(streams.ifEmpty(create))
  }
}
