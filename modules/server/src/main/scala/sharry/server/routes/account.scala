package sharry.server.routes

import cats.data.{Validated, ValidatedNel}
import cats.implicits._
import fs2.{Stream, Task}
import com.github.t3hnar.bcrypt._
import shapeless.{::,HNil}
import spinoco.fs2.http.routing._

import sharry.common.streams
import sharry.common.data.Account
import sharry.store.account.AccountStore
import sharry.server.config.{AuthConfig, WebConfig}
import sharry.server.authc._
import sharry.server.paths
import sharry.server.email.Address
import sharry.server.routes.syntax._

object account {

  def endpoint(auth: Authenticate, authCfg: AuthConfig, store: AccountStore, cfg: WebConfig) =
    choice2(listLogins(auth, store)
      , createAccount(auth, store)
      , modifyAccount(auth, store)
      , updateEmail(authCfg, store)
      , updatePassword(authCfg, store)
      , getAccount(auth, store))

  def createAccount(auth: Authenticate, store: AccountStore): Route[Task] =
    Put >> paths.accounts.matcher >> authz.admin(auth) >> jsonBody[Account] map { (a: Account) =>
      val acc = a.copy(
        password = a.password.map(_.bcrypt),
        email = a.email.filter(_.nonEmpty)
      )
      validateAccount(acc) match {
        case Validated.Invalid(errs) =>
          Stream.emit(BadRequest.message(s"Invalid account: ${errs.toList.mkString(", ")}"))
        case Validated.Valid(_) =>
          store.getAccount(acc.login).
            map(a => BadRequest.message("The account already exists")).
            through(streams.ifEmpty {
              store.createAccount(acc).
                map(_ => Created.body(acc.noPass))
            })
      }
    }

  def validateEmail(address: String): ValidatedNel[String, Unit] = {
    val parsed = Address.parse(address).
      map(_ => ()).
      attempt.
      map(_.leftMap(_.getMessage))

    Validated.
      fromEither(parsed.unsafeRun).
      toValidatedNel
  }

  def validateAccount(a: Account): ValidatedNel[String, Account] = {
    // validate email
    val v1 = a.email.map(validateEmail).getOrElse(Validated.valid(()).toValidatedNel)

    // validate rest of account
    val v2 = Account.validate(a).map(_ => ())

    (v1 |+| v2).map(_ => a)
  }

  def modifyAccount(auth: Authenticate, store: AccountStore): Route[Task] =
    Post >> paths.accounts.matcher >> authz.admin(auth) >> jsonBody[Account] map {
      (account: Account) =>
        validateAccount(account) match {
          case Validated.Invalid(errs) =>
            Stream.emit(BadRequest.message(s"Invalid account: ${errs.toList.mkString(", ")}"))
          case _ =>
            store.getAccount(account.login).
              map(dba => account.copy(
                password = account.password match {
                  case Some(pw) if pw.nonEmpty => Some(pw.bcrypt)
                  case _ => dba.password
                },
                email = account.email.filter(_.nonEmpty)
              )).
              flatMap(a => store.updateAccount(a).map(_ => a)).
              map(Ok.body(_)).
              through(NotFound.whenEmpty)
        }
    }

  def updateEmail(cfg: AuthConfig, store: AccountStore): Route[Task] =
    Post >> paths.profileEmail.matcher >> authz.user(cfg) :: jsonBody[Account] map {
      case login :: account :: HNil =>
        validateAccount(account) match {
          case Validated.Invalid(errs) =>
            Stream.emit(BadRequest.message(s"Invalid account: ${errs.toList.mkString(", ")}"))
          case _ =>
            store.updateEmail(login, account.email).
              flatMap {
                case true => store.getAccount(login).map(Ok.body(_))
                case false => Stream.emit(NotFound.noBody)
              }
        }
    }

  def updatePassword(cfg: AuthConfig, store: AccountStore): Route[Task] =
    Post >> paths.profilePassword.matcher >> authz.user(cfg) :: jsonBody[Account] map {
      case login :: account :: HNil =>
        validateAccount(account) match {
          case Validated.Invalid(errs) =>
            Stream.emit(BadRequest.message(s"Invalid account: ${errs.toList.mkString(", ")}"))
          case _ =>
            store.updatePassword(login, account.password.map(_.bcrypt)).
              flatMap {
                case true => store.getAccount(login).map(Ok.body(_))
                case false => Stream.emit(NotFound.noBody)
              }
        }
    }

  def listLogins(auth: Authenticate, store: AccountStore): Route[Task] =
    Get >> paths.accounts.matcher/empty >> authz.admin(auth) / param[String]("q").? map { (q: Option[String]) =>
      Stream.eval(store.listLogins(q.getOrElse(""), None).runLog).
        map(Ok.body(_))
    }

  def getAccount(auth: Authenticate, store: AccountStore): Route[Task] =
    Get >> paths.accounts.matcher / as[String] </ authz.admin(auth) map { login =>
      Account.validateLogin(login) match {
        case Validated.Invalid(errs) =>
          Stream.emit(BadRequest.message(s"Invalid login: ${errs.toList.mkString(", ")}"))
        case _ =>
          store.getAccount(login).map(Ok.body(_))
      }
    }
}
