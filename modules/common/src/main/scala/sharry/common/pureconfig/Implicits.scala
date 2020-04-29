package sharry.common.pureconfig

import sharry.common._
import _root_.pureconfig._
import _root_.pureconfig.error.{CannotConvert, FailureReason}
import scodec.bits.ByteVector

import scala.reflect.ClassTag

object Implicits {
  implicit val lenientUriReader: ConfigReader[LenientUri] =
    ConfigReader[String].emap(reason(LenientUri.parse))

  implicit val durationReader: ConfigReader[Duration] =
    ConfigReader[scala.concurrent.duration.Duration].map(sd => Duration(sd))

  implicit val passwordReader: ConfigReader[Password] =
    ConfigReader[String].map(Password(_))

  implicit val identReader: ConfigReader[Ident] =
    ConfigReader[String].emap(reason(Ident.fromString))

  implicit val byteVectorReader: ConfigReader[ByteVector] =
    ConfigReader[String].emap(reason { str =>
      if (str.startsWith("hex:")) ByteVector.fromHex(str.drop(4)).toRight("Invalid hex value.")
      else if (str.startsWith("b64:"))
        ByteVector.fromBase64(str.drop(4)).toRight("Invalid Base64 string.")
      else ByteVector.encodeUtf8(str).left.map(_.getMessage())
    })

  implicit val byteSizeReader: ConfigReader[ByteSize] =
    ConfigReader[String].emap(reason(ByteSize.parse))

  def reason[A: ClassTag](f: String => Either[String, A]): String => Either[FailureReason, A] =
    in =>
      f(in).left.map(str => CannotConvert(in, implicitly[ClassTag[A]].runtimeClass.toString, str))
}
