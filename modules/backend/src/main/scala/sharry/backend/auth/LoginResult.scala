package sharry.backend.auth

sealed trait LoginResult {
  def toEither: Either[String, AuthToken]
}

object LoginResult {
  case class Ok(session: AuthToken) extends LoginResult {
    val toEither = Right(session)
  }
  case object InvalidAuth extends LoginResult {
    val toEither = Left("Authentication failed.")
  }
  case object InvalidTime extends LoginResult {
    val toEither = Left("Authentication failed.")
  }

  def ok(session: AuthToken): LoginResult = Ok(session)
  def invalidAuth: LoginResult            = InvalidAuth
  def invalidTime: LoginResult            = InvalidTime
}
