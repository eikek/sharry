package sharry.common

import cats.implicits.*

sealed trait EnvMode { self: Product =>

  val name: String =
    productPrefix.toLowerCase

  def isDev: Boolean
  def isProd: Boolean
}

object EnvMode {
  private val sysProp = "sharry.env"
  private val envName = "SHARRY_ENV"

  case object Dev extends EnvMode {
    val isDev = true
    val isProd = false
  }
  case object Prod extends EnvMode {
    val isDev = false
    val isProd = true
  }

  def dev: EnvMode = Dev
  def prod: EnvMode = Prod

  def fromString(s: String): Either[String, EnvMode] =
    s.toLowerCase match {
      case s if s.startsWith("dev")  => Right(Dev)
      case s if s.startsWith("prod") => Right(Prod)
      case _                         => Left(s"Invalid env mode: $s")
    }

  def read: Either[String, Option[EnvMode]] = {
    def normalize(str: String): Option[String] =
      Option(str).map(_.trim).filter(_.nonEmpty)

    normalize(System.getProperty(sysProp))
      .orElse(normalize(System.getenv(envName)))
      .traverse(fromString)
  }

  lazy val current: EnvMode =
    read.toOption.flatten.getOrElse(prod)

}
