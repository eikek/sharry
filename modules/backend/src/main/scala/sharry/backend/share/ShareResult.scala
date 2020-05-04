package sharry.backend.share

import cats.implicits._
import cats.Applicative

sealed trait ShareResult[+A] {

  def toOption: Option[A]

  def fold[B](
      f1: A => B,
      f2: ShareResult.PasswordMismatch.type => B,
      f3: ShareResult.PasswordMissing.type => B
  ): B

  def map[B](f: A => B): ShareResult[B]

  def mapF[F[_]: Applicative, B](f: A => F[B]): F[ShareResult[B]]
}

object ShareResult {

  def apply[A](value: A): ShareResult[A] =
    Success(value)

  case class Success[A](value: A) extends ShareResult[A] {
    def toOption: Option[A] = Some(value)

    def fold[B](
        f1: A => B,
        f2: ShareResult.PasswordMismatch.type => B,
        f3: ShareResult.PasswordMissing.type => B
    ): B = f1(value)

    def map[B](f: A => B): ShareResult[B] =
      Success(f(value))

    def mapF[F[_]: Applicative, B](f: A => F[B]): F[ShareResult[B]] =
      f(value).map(Success.apply)
  }

  case object PasswordMismatch extends ShareResult[Nothing] {
    def toOption: Option[Nothing] = None

    def fold[B](
        f1: Nothing => B,
        f2: ShareResult.PasswordMismatch.type => B,
        f3: ShareResult.PasswordMissing.type => B
    ): B = f2(this)

    def mapF[F[_]: Applicative, B](f: Nothing => F[B]): F[ShareResult[B]] =
      (this: ShareResult[B]).pure[F]

    def map[B](f: Nothing => B) =
      this: ShareResult[B]

  }

  case object PasswordMissing extends ShareResult[Nothing] {
    def toOption: Option[Nothing] = None

    def fold[B](
        f1: Nothing => B,
        f2: ShareResult.PasswordMismatch.type => B,
        f3: ShareResult.PasswordMissing.type => B
    ): B = f3(this)

    def mapF[F[_]: Applicative, B](f: Nothing => F[B]): F[ShareResult[B]] =
      (this: ShareResult[B]).pure[F]

    def map[B](f: Nothing => B) =
      this: ShareResult[B]

  }

}
