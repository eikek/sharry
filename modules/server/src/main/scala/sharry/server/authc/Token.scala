package sharry.server.authc

import java.time.Instant
import java.time.temporal.TemporalAmount

import scala.util.Try
import scodec.bits.ByteVector
import com.github.t3hnar.bcrypt
import sharry.store.data.Account
import sharry.store.data.sign

case class Token(salt: String, login: String, ends: Instant, signature: String) {
  def asString = s"${salt}%${login}%${ends.toString}%${signature}"

  def verify(now: Instant, appKey: ByteVector): Boolean = {
    val sigv = sign.sign(appKey, s"${salt}%${login}%${ends.toString}").toHex
    now.isBefore(ends) && sigv.zip(signature).forall({ case (a, b) => a == b })
  }

  def extend(duration: TemporalAmount, appKey: ByteVector) =
    Token(login, ends.plus(duration), appKey)
}

object Token {
  val invalid = Token("invalid", Instant.ofEpochMilli(0), ByteVector.view("invalid".getBytes))

  def apply(login: String, ends: Instant, appKey: ByteVector): Token = {
    val salt = bcrypt.generateSalt
    val data = s"${salt}%${login}%${ends.toString}"
    val sig = sign.sign(appKey, data)
    Token(salt, login, ends, sig.toHex)
  }

  def parse(s: String): Token = {
    val parts = s.split("%", 4).toList
    parts match {
      case salt :: login :: ends :: sig :: Nil
          if (Account.validateLogin(login).isValid) =>
        Try(Token(salt, login, Instant.parse(ends), sig)).
          toOption.
          getOrElse(Token(salt, login, Instant.ofEpochMilli(0), sig))
      case _ =>
        invalid
    }
  }
}
