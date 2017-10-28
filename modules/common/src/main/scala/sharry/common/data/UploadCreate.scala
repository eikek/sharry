package sharry.common.data

import java.time.Duration
import cats.syntax.either._
import io.circe._, io.circe.generic.semiauto._

/** Used to create uploads */
case class UploadCreate(id: String, description: String, validity: String, maxdownloads: Int, password: String)

object UploadCreate {
  def parseValidity(s: String): Either[String, Duration] = {
    val make: Long => Either[String, Duration] =
      s.toLowerCase.last match {
        case 'h' => n => Right(Duration.ofHours(n))
        case 'd' => n => Right(Duration.ofDays(n))
        case 'm' => n => Right(Duration.ofDays(30 * n))
        case _ => n => Left(s"Wrong validity: $s")
      }
    Either.catchNonFatal(s.init.toLong).
      left.map(_.getMessage).
      flatMap(make)
  }

  implicit val _uploadMetaDec: Decoder[UploadCreate] = deriveDecoder[UploadCreate]
  implicit val _uploadMetaEnc: Encoder[UploadCreate] = deriveEncoder[UploadCreate]

}
