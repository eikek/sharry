package sharry.common.config

import java.nio.file.{Path => JPath}

import scala.reflect.ClassTag

import fs2.io.file.Path

import sharry.common._

import com.comcast.ip4s.{Host, Port}
import pureconfig._
import pureconfig.configurable.genericMapReader
import pureconfig.error.{CannotConvert, FailureReason}
import scodec.bits.ByteVector

trait Implicits {
  implicit val pathReader: ConfigReader[Path] =
    ConfigReader[JPath].map(Path.fromNioPath)

  implicit val lenientUriReader: ConfigReader[LenientUri] =
    ConfigReader[String].emap(reason(LenientUri.parse))

  implicit val durationReader: ConfigReader[Duration] =
    ConfigReader[scala.concurrent.duration.Duration].map(sd => Duration(sd))

  implicit val passwordReader: ConfigReader[Password] =
    ConfigReader[String].map(Password(_))

  implicit val identReader: ConfigReader[Ident] =
    ConfigReader[String].emap(reason(Ident.fromString))

  implicit def identMapReader[B: ConfigReader]: ConfigReader[Map[Ident, B]] =
    genericMapReader[Ident, B](reason(Ident.fromString))

  implicit val byteVectorReader: ConfigReader[ByteVector] =
    ConfigReader[String].emap(reason { str =>
      if (str.startsWith("hex:"))
        ByteVector.fromHex(str.drop(4)).toRight("Invalid hex value.")
      else if (str.startsWith("b64:"))
        ByteVector.fromBase64(str.drop(4)).toRight("Invalid Base64 string.")
      else ByteVector.encodeUtf8(str).left.map(_.getMessage())
    })

  implicit val byteSizeReader: ConfigReader[ByteSize] =
    ConfigReader[String].emap(reason(ByteSize.parse))

  implicit val signupModeReader: ConfigReader[SignupMode] =
    ConfigReader[String].emap(reason(SignupMode.fromString))

  implicit val portReader: ConfigReader[Port] =
    ConfigReader[Int].emap(reason(n => Port.fromInt(n).toRight(s"Invalid port: $n")))

  implicit val hostReader: ConfigReader[Host] =
    ConfigReader[String].emap(
      reason(s => Host.fromString(s).toRight(s"Invalid host address: $s"))
    )

  def reason[I, A: ClassTag](
      f: I => Either[String, A]
  ): I => Either[FailureReason, A] =
    in =>
      f(in).left.map(str =>
        CannotConvert(in.toString, implicitly[ClassTag[A]].runtimeClass.toString, str)
      )
}

object Implicits extends Implicits
