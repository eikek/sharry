package sharry.backend.share

import cats.Applicative
import cats.implicits._

import sharry.common._

sealed trait UploadResult[+A] {

  def flatMap[B](f: A => UploadResult[B]): UploadResult[B]

  def map[B](f: A => B): UploadResult[B] =
    flatMap(a => UploadResult.Success(f(a)))

  def mapF[F[_]: Applicative, B](f: A => F[B]): F[UploadResult[B]] =
    flatMapF[F, B](a => f(a).map(UploadResult.success))

  def flatMapF[F[_]: Applicative, B](f: A => F[UploadResult[B]]): F[UploadResult[B]]

  def exists(f: A => Boolean): Boolean =
    toOption.exists(f)

  def forall(f: A => Boolean): Boolean =
    toOption.forall(f)

  def toOption: Option[A]

  def checkSize(max: ByteSize)(f: A => ByteSize): UploadResult[A] =
    if (toOption.forall(e => f(e) <= max)) this
    else UploadResult.sizeExceeded(max)

  def checkValidity(max: Duration)(f: A => Duration): UploadResult[A] =
    if (toOption.forall(e => f(e) <= max)) this
    else UploadResult.validityExceeded(max)
}

object UploadResult {
  def apply[A](v: A): UploadResult[A] =
    Success(v)

  def success[A](v: A): UploadResult[A] =
    apply(v)

  def validityExceeded[A](max: Duration): UploadResult[A] =
    ValidityExceeded(max)

  def sizeExceeded[A](max: ByteSize): UploadResult[A] =
    SizeExceeded(max)

  def permanentError[A](msg: String): UploadResult[A] =
    PermanentError(msg)

  case class Success[A](value: A) extends UploadResult[A] {
    def flatMap[B](f: A => UploadResult[B]): UploadResult[B] =
      f(value)

    def flatMapF[F[_]: Applicative, B](f: A => F[UploadResult[B]]): F[UploadResult[B]] =
      f(value)

    def toOption: Option[A] = Some(value)
  }

  case class ValidityExceeded(max: Duration) extends UploadResult[Nothing] {
    def flatMap[B](f: Nothing => UploadResult[B]): UploadResult[B] =
      this

    def flatMapF[F[_]: Applicative, B](
        f: Nothing => F[UploadResult[B]]
    ): F[UploadResult[B]] =
      (this: UploadResult[B]).pure[F]

    def toOption: Option[Nothing] = None
  }

  case class SizeExceeded(max: ByteSize) extends UploadResult[Nothing] {
    def flatMap[B](f: Nothing => UploadResult[B]): UploadResult[B] =
      this

    def flatMapF[F[_]: Applicative, B](
        f: Nothing => F[UploadResult[B]]
    ): F[UploadResult[B]] =
      (this: UploadResult[B]).pure[F]

    def toOption: Option[Nothing] = None
  }

  case class PermanentError(msg: String) extends UploadResult[Nothing] {
    def flatMap[B](f: Nothing => UploadResult[B]): UploadResult[B] =
      this

    def flatMapF[F[_]: Applicative, B](
        f: Nothing => F[UploadResult[B]]
    ): F[UploadResult[B]] =
      (this: UploadResult[B]).pure[F]

    def toOption: Option[Nothing] = None
  }
}
