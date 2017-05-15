package sharry.store.data

import cats.data.{Validated, ValidatedNel}
import cats.implicits._

case class Account(
  login: String,
  password: Option[String],
  email: Option[String] = None,
  enabled: Boolean = true,
  admin: Boolean = false,
  extern: Boolean = false) {

  Account.validateLogin(login) match {
    case Validated.Invalid(err) => sys.error(err.toList.mkString(", "))
    case _ =>
  }

  def noPass = password.map(_ => copy(password = Some("***"))).getOrElse(this)
}


object Account {

  /** Validate a login string. Return a list of error messages or the
    * login if it is correct. */
  def validateLogin(login: String): ValidatedNel[String, String] = {
    def validate(b: => Boolean, err: String) =
      if (b) Validated.valid(()) else Validated.invalidNel(err)

    val alpha = ('a' to 'z') ++ ('A' to 'Z')
    val v1 = validate(login.nonEmpty, "login must not be empty")
    val v2 = validate(login.nonEmpty && (alpha contains login(0)), "login must start with a letter")
    val v3 = validate(login.matches("[a-zA-Z0-9_]+"), "login must be alphanumeric plus _")
    (v1 |+| v2 |+| v3).map(_ => login)
  }

  def validate(a: Account): ValidatedNel[String, Account] = {
    // internal accounts need a password
    val v1: ValidatedNel[String, Unit] =
      if (a.extern || a.password.isDefined) Validated.valid(())
      else Validated.invalidNel("Internal accounts require a password")

    val v2: ValidatedNel[String, Unit] = validateLogin(a.login).map(_ => ())

    (v1 |+| v2).map(_ => a)
  }

  def tryApply(
    login: String,
    password: Option[String],
    email: Option[String] = None,
    enabled: Boolean = true,
    admin: Boolean = false,
    extern: Boolean = false): ValidatedNel[String, Account] = {

    validateLogin(login).map { _ =>
      Account(login, password, email, enabled, admin, extern)
    }
  }

  def newInternal(login: String, password: String) =
    Account(login, Some(password), extern = false, enabled = true)

  def newExtern(login: String) =
    Account(login, None, extern = true, enabled = true)

  object Internal {
    def unapply(a: Account): Option[(String, Option[String])] =
      if (a.extern) None
      else Some((a.login, a.password))
  }

  object External {
    def unapply(a: Account): Option[String] =
      if (a.extern) Some(a.login)
      else None
  }
}
