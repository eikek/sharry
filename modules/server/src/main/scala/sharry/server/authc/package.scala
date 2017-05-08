package sharry.server

import cats.syntax.either._
import scodec.{Err, Codec}
import scodec.bits.ByteVector

import sharry.store.data._

package object authc {
  type AuthResult = Either[String, Account]

  object AuthResult {
    val failed = fail("Login failed")
    def fail(msg: String): AuthResult = Left(msg)
    def ok(a: Account): AuthResult = Right(a)
    def apply(a: Account): AuthResult = ok(a)
  }

  def parse[A](str: String, codec: Codec[A]): Either[Err, A] =
    for {
      bv <- ByteVector.encodeUtf8(str).leftMap(ex => Err(ex.getMessage))
      a <- codec.decodeValue(bv.bits).toEither
    } yield a
}
