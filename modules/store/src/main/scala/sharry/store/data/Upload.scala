package sharry.store.data

import java.time.{Duration, Instant}
import cats.data.{Validated, NonEmptyList => Nel}
import cats.implicits._
import com.github.t3hnar.bcrypt._
import io.circe._, io.circe.generic.semiauto._
import sharry.common.data.UploadWeb
import sharry.common.JsonCodec

case class Upload (
  id: String
    , login: String
    , validity: Duration
    , maxDownloads: Int
    , alias: Option[String] = None
    , description: Option[String] = None
    , password: Option[String] = None
    , created: Instant = Instant.now
    , downloads: Int = 0
    , lastDownload: Option[Instant] = None
    , publishId: Option[String] = None
    , publishDate: Option[Instant] = None
    , aliasName: Option[String] = None
) {

  lazy val validUntil = publishDate.map(pd => pd.plus(validity))

}

object Upload {
  def isValid(up: Upload, now: Instant, downloads: Int): Validated[Nel[String], Unit] =
    up.publishDate match {
      case Some(pd) =>
        val until =
          if (pd.plus(up.validity).isAfter(now)) Validated.valid(())
          else Validated.invalid(Nel.of("The validity time has expired."))

        val dls =
          if (up.maxDownloads > downloads) Validated.valid(())
          else Validated.invalid(Nel.of("The maximum number of downloads is reached."))

        List(until, dls).reduce(_ combine _)

      case None =>
        Validated.invalid(Nel.of("This is not a published upload"))
    }

  def checkPassword(up: Upload, pw: Option[String]): Validated[String, Unit] =
    (up.password, pw) match {
      case (Some(db), Some(given)) =>
        if (given.isBcrypted(db)) Validated.valid(())
        else Validated.invalid("The password is not valid")
      case (Some(_), _) =>
        Validated.invalid("Access requires a password.")
      case _ =>
        Validated.valid(())
    }

  def checkUpload(up: Upload, now: Instant, downloads: Int, password: Option[String]): Validated[Nel[String], Unit] =
    isValid(up, now, downloads).combine(checkPassword(up, password).toValidatedNel)

  implicit val _uploadDec: Decoder[Upload] = {
    import JsonCodec._
    deriveDecoder[Upload]
  }

  implicit val _uploadEnc: Encoder[Upload] = {
    UploadWeb._uploadWebEnc.contramap(fromUpload _)
  }
  private def fromUpload(up: Upload): UploadWeb =
    UploadWeb(up.id
      , up.login
      , up.alias
      , up.aliasName
      , up.validity
      , up.maxDownloads
      , up.password.isDefined
      , Upload.isValid(up, Instant.now, up.downloads).swap.toOption.map(_.toList).getOrElse(Nil)
      , up.description
      , up.created
      , up.downloads
      , up.lastDownload
      , up.publishId
      , up.publishDate
      , up.validUntil
    )

}


case class UploadFile(
  uploadId: String
    , fileId: String
    , filename: String
    , downloads: Int
    , lastDownload: Option[Instant]
    , clientFileId: String
)

object UploadFile {
  import JsonCodec._

  implicit val _uploadFileDec: Decoder[UploadFile] = deriveDecoder[UploadFile]
  implicit val _uploadFileEnc: Encoder[UploadFile] = deriveEncoder[UploadFile]
}
