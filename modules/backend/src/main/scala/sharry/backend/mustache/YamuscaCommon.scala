package sharry.backend.mustache

import sharry.common._

import bitpeace.Mimetype
import yamusca.imports._

trait YamuscaCommon {

  implicit def yamuscaIntMapConverter[A](implicit
      ca: ValueConverter[Map[String, A]]
  ): ValueConverter[Map[Int, A]] =
    ValueConverter.of(m => ca(m.map(t => (t._1.toString, t._2))))

  implicit val yamuscaIdentConverter: ValueConverter[Ident] =
    ValueConverter.of(m => Value.fromString(m.id))

  implicit val yamuscaMimetypeConverter: ValueConverter[Mimetype] =
    ValueConverter.of(m => Value.fromString(m.asString))

  implicit val yamuscaBytesizeConverter: ValueConverter[ByteSize] =
    ValueConverter.of(m => Value.fromString(m.bytes.toString))

  implicit val yamuscaUriConverter: ValueConverter[LenientUri] =
    ValueConverter.of(m => Value.fromString(m.asString))

  implicit val yamuscaDurationConverter: ValueConverter[Duration] =
    ValueConverter.of(m => Value.fromString(m.millis.toString))

  implicit val yamuscaPasswordConverter: ValueConverter[Password] =
    ValueConverter.of(m => Value.fromString(m.pass))

  implicit def yamuscaSignupModeConverter: ValueConverter[SignupMode] =
    ValueConverter.of(m => Value.fromString(m.name))

}

object YamuscaCommon extends YamuscaCommon
