package sharry.common

import javax.activation.{MimeType => JMimeType}
import scala.collection.JavaConverters._
import scala.util.Try
import io.circe._

/** Utility around `javax.activation.MimeType'. */
object mime {

  case class MimeType(
    primary: String,
    sub: String,
    params: Map[String, String] = Map.empty) {

    def orElse(other: MimeType): MimeType =
      if (this == MimeType.unknown) other else this

    def baseType = s"${primary}/${sub}"

    def param(name: String): Option[String] =
      params.get(name.toLowerCase)

    def param(name: String, value: String): MimeType =
      copy(params = params.updated(name, value))

    def baseEqual(other: MimeType): Boolean =
      baseType == other.baseType

    def asString = {
      params.foldLeft(baseType) { case (s, (name, value)) =>
        s + s"; $name=$value"
      }
    }
  }

  object MimeType {
    val `application/octet-stream` = MimeType("application", "octet-stream")
    val unknown = `application/octet-stream`
    val `application/pdf` = MimeType("application", "pdf")
    val `text/html` = MimeType("text", "html")
    val `application/x-xz` = MimeType("application", "x-xz")
    val `application/zip` = MimeType("application", "zip")

    def apply(primary: String, subtype: String): MimeType =
      normalize(new JMimeType(primary, subtype).asScala)

    def parse(mt: String): Try[MimeType] =
      Try(new JMimeType(mt)).map(_.asScala).map(normalize)

    def normalize(mt: MimeType): MimeType =
      if (!mt.baseType.contains("unknown")) mt
      else unknown

    val extension = Map(
      `application/pdf` -> "pdf",
      `text/html` -> "html",
      `application/x-xz` -> "xz"
    )

    implicit val _mimeTypeDec: Decoder[MimeType] = Decoder.decodeString.map(s => MimeType.parse(s).get)
    implicit val _mimeTypeEnc: Encoder[MimeType] = Encoder.encodeString.contramap[MimeType](_.asString)
  }

  object BaseType {
    def unapply(mt: MimeType): Option[(String, String)] =
      Some(mt.primary -> mt.sub)
  }

  implicit class MimeTypeOps(mt: JMimeType) {
    def asScala: MimeType = {
      val paramNames = mt.getParameters.getNames.asScala.map(_.toString)
      val params = paramNames.foldLeft(Map.empty[String, String]) {
        (map, name) => map.updated(name.toLowerCase, mt.getParameter(name))
      }
      MimeType(mt.getPrimaryType, mt.getSubType, params)
    }

    def preferredExtension = MimeType.extension.get(asScala)
  }
}
