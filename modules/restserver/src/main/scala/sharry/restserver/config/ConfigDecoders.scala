package sharry.restserver.config

import scala.jdk.CollectionConverters.*

import cats.Show
import cats.syntax.all.*

import sharry.common.*
import sharry.logging.Level
import sharry.logging.LogConfig

import ciris.*
import com.comcast.ip4s.{Host, Port}
import com.typesafe.config.ConfigValue as TCValue
import org.http4s.Uri
import scodec.bits.ByteVector

private[config] trait ConfigDecoders:
  extension [A, B](self: ConfigDecoder[A, B])
    def emap[C](typeName: String)(f: B => Either[String, C])(using Show[B]) =
      self.mapEither((key, b) =>
        f(b).left.map(err => ConfigError.decode(typeName, key, b))
      )

  given ConfigDecoder[TCValue, String] =
    ConfigDecoder[TCValue].map(_.atKey("a").getString("a"))

  given ConfigDecoder[TCValue, Double] =
    ConfigDecoder[TCValue].map(_.atKey("a").getDouble("a"))

  given ConfigDecoder[TCValue, Long] =
    ConfigDecoder[TCValue].map(_.atKey("a").getLong("a"))

  given [A](using ConfigDecoder[TCValue, A]): ConfigDecoder[TCValue, List[A]] =
    ConfigDecoder[TCValue].mapEither { (cfgKey, cv) =>
      val inner = cv.atKey("a").getList("a")
      inner.asScala.toList.traverse(e => ConfigDecoder[TCValue, A].decode(cfgKey, e))
    }

  given [K, A](using
      ConfigDecoder[String, K],
      ConfigDecoder[TCValue, A]
  ): ConfigDecoder[TCValue, Map[K, A]] =
    ConfigDecoder[TCValue].mapEither { (cfgKey, cv) =>
      val inner = cv.atKey("a").getConfig("a")
      inner.root.keySet.asScala.toList
        .traverse { key =>
          val value = inner.getObject(key)
          ConfigDecoder[String, K]
            .decode(cfgKey, key)
            .flatMap(k =>
              ConfigDecoder[TCValue, A].decode(cfgKey, value).map(v => k -> v)
            )
        }
        .map(_.toMap)
    }

  given [A](using ConfigDecoder[String, A]): ConfigDecoder[TCValue, A] =
    ConfigDecoder[TCValue, String].as[A]

  given ConfigDecoder[String, Duration] =
    ConfigDecoder[String].as[scala.concurrent.duration.Duration].map(Duration.apply)

  given ConfigDecoder[String, LenientUri] =
    ConfigDecoder[String].emap("LenientUri")(LenientUri.parse)

  given ConfigDecoder[String, ByteVector] =
    ConfigDecoder[String].emap("ByteVector") { str =>
      if (str.startsWith("hex:"))
        ByteVector.fromHex(str.drop(4)).toRight(s"Invalid hex value: $str")
      else if (str.startsWith("b64:"))
        ByteVector.fromBase64(str.drop(4)).toRight(s"Invalid Base64 string: $str")
      else ByteVector.encodeUtf8(str).left.map(_.getMessage())
    }

  given ConfigDecoder[String, Ident] =
    ConfigDecoder[String].emap("Ident")(Ident.fromString)

  given ConfigDecoder[String, Password] =
    ConfigDecoder[String].map(Password.apply)

  given ConfigDecoder[String, Uri] =
    ConfigDecoder[String].mapOption("Uri")(Uri.fromString(_).toOption)

  given ConfigDecoder[String, Host] =
    ConfigDecoder[String].mapOption("Host")(Host.fromString)

  given ConfigDecoder[String, Port] =
    ConfigDecoder[String].mapOption("Port")(Port.fromString)

  given ConfigDecoder[String, ByteSize] =
    ConfigDecoder[String].emap("ByteSize")(ByteSize.parse)

  given ConfigDecoder[String, Level] =
    ConfigDecoder[String].emap("Level")(Level.fromString)

  given ConfigDecoder[String, LogConfig.Format] =
    ConfigDecoder[String].emap("LogFormat")(LogConfig.Format.fromString)
