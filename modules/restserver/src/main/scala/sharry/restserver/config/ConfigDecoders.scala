package sharry.restserver.config

import scala.jdk.CollectionConverters.*

import cats.Show
import cats.syntax.all.*
import fs2.io.file.Path

import sharry.common.*
import sharry.logging.Level
import sharry.logging.LogConfig
import sharry.store.FileStoreType

import ciris.*
import com.comcast.ip4s.{Host, Port}
import com.typesafe.config.ConfigValue as TCValue
import emil.javamail.syntax.*
import emil.{MailAddress, SSLType}
import org.http4s.Uri
import scodec.bits.ByteVector
import yamusca.data.Template

private[config] trait ConfigDecoders:
  extension [A, B](self: ConfigDecoder[A, B])
    def emap[C](typeName: String)(f: B => Either[String, C])(using Show[B]) =
      self.mapEither((key, b) =>
        f(b).left.map(err => ConfigError.decode(typeName, key, b))
      )

  extension [A](self: ConfigValue[Effect, List[A]])
    def listflatMap[B](f: A => ConfigValue[Effect, B]): ConfigValue[Effect, List[B]] =
      self.flatMap(ids =>
        ids.foldLeft(ConfigValue.loaded(ConfigKey(""), List.empty[B])) { (cv, id) =>
          cv.flatMap(l => f(id).map(_ :: l))
        }
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
          val value = inner.getValue(s"\"$key\"")
          ConfigDecoder[String, K]
            .decode(cfgKey, key)
            .flatMap(k =>
              ConfigDecoder[TCValue, A].decode(cfgKey, value).map(v => k -> v)
            )
        }
        .map(_.toMap)
    }

  given [A](using ConfigDecoder[String, A]): ConfigDecoder[String, List[A]] =
    ConfigDecoder[String].mapEither { (ckey, str) =>
      str
        .split(',')
        .toList
        .map(_.trim)
        .filter(_.nonEmpty)
        .traverse(
          ConfigDecoder[String, A].decode(ckey, _)
        )
    }

  given [A, B](using ConfigDecoder[A, B]): ConfigDecoder[List[A], List[B]] =
    ConfigDecoder.instance { (ckey, lista) =>
      lista.traverse(ConfigDecoder[A, B].decode(ckey, _))
    }

  given [A](using ConfigDecoder[String, A]): ConfigDecoder[TCValue, A] =
    ConfigDecoder[TCValue, String].as[A]

  given ConfigDecoder[String, Duration] =
    ConfigDecoder[String].emap("Duration")(Duration.fromString)

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

  given ConfigDecoder[String, FileStoreType] =
    ConfigDecoder[String].emap("FileStoreType")(FileStoreType.fromString)

  given ConfigDecoder[String, Path] =
    ConfigDecoder[String].map(Path(_))

  given ConfigDecoder[String, SignupMode] =
    ConfigDecoder[String].emap("SignupMode")(SignupMode.fromString)

  given ConfigDecoder[String, SSLType] =
    ConfigDecoder[String].emap("SSLType")(SSLType.fromString)

  given ConfigDecoder[String, MailAddress] =
    ConfigDecoder[String].emap("MailAddress")(MailAddress.parse)

  given ConfigDecoder[String, Option[MailAddress]] =
    ConfigDecoder[String].mapEither { (key, s) =>
      if (s.isEmpty) Right(None)
      else ConfigDecoder[String, MailAddress].decode(key, s).map(Some(_))
    }

  given ConfigDecoder[String, Template] =
    ConfigDecoder[String].emap("Template")(str =>
      yamusca.parser.parse(str).left.map(_._2)
    )
