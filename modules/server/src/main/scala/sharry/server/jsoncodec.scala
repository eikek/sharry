package sharry.server

import java.time.{Duration, Instant}
import cats.syntax.either._
import io.circe.generic.semiauto._, io.circe._
import sharry.server.authc.Token
import sharry.server.email._
import sharry.store.data._
import sharry.common.mime._
import sharry.common.sizes._

object jsoncodec {
  case class UserPass(login: String, pass: String)
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
  }

  case class UploadWeb(
    id: String
      , login: String
      , alias: Option[String]
      , aliasName: Option[String]
      , validity: Duration
      , maxDownloads: Int
      , requiresPassword: Boolean
      , validated: List[String]
      , description: Option[String] = None
      , created: Instant = Instant.now
      , downloads: Int = 0
      , lastDownload: Option[Instant] = None
      , publishId: Option[String] = None
      , publishDate: Option[Instant] = None
      , validUntil: Option[Instant] = None
  )
  object UploadWeb {
    def fromUpload(up: Upload): UploadWeb =
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

  case class AliasUpdate(id: String, login: String, name: String, validity: String, enable: Boolean)

  object AliasUpdate {
    implicit val _jsonDecoder: Decoder[AliasUpdate] = deriveDecoder[AliasUpdate]
  }

  case class Pass(password: String)

  object Pass {
    implicit val jsonDecoder: Decoder[Pass] = deriveDecoder[Pass]
  }

  implicit val _simpleMailDecoder: Decoder[routes.mail.SimpleMail] = deriveDecoder[routes.mail.SimpleMail]

  implicit val _addressEncoder: Encoder[Address] = Encoder.encodeString.contramap[Address](_.mail.toString)
  implicit val _sendResultEncoder: Encoder[routes.mail.SendResult] = deriveEncoder[routes.mail.SendResult]


  implicit val _aliasDecoder: Decoder[Alias] = deriveDecoder[Alias]
  implicit val _aliasEncoder: Encoder[Alias] = deriveEncoder[Alias]


  implicit val _userPassDec: Decoder[UserPass] = deriveDecoder[UserPass]
  implicit val _userPassEnc: Encoder[UserPass] = deriveEncoder[UserPass]

  private def nonEmpty(o: Option[String]): Option[String] =
    o.map(_.trim).filter(_.nonEmpty)

  implicit val _accountDec: Decoder[Account] = {
    val dec = Decoder.forProduct6("login", "password", "email", "enabled", "admin", "extern")(Account.tryApply)
    dec.emap(_.toEither.leftMap(errs => errs.toList.mkString(", "))).
      map(a => a.copy(password = nonEmpty(a.password), email = nonEmpty(a.email)))
  }

  implicit val _accountEnc: Encoder[Account] = deriveEncoder[Account].
    contramap(a => a.copy(password = a.password.map(_ => "***")))

  implicit val _tokenEnc: Encoder[Token] =
    Encoder.forProduct1("token")(t => t.asString)

  implicit val _tokenDec: Decoder[Token] =
    Decoder.forProduct1("token")(Token.parse)

  implicit val _instantDec: Decoder[Instant] = Decoder.decodeString.map(Instant.parse)
  implicit val _instantEnc: Encoder[Instant] = Encoder.encodeString.contramap[Instant](_.toString)

  implicit val _durationDec: Decoder[Duration] = Decoder.decodeString.map(Duration.parse)
  implicit val _durationEnc: Encoder[Duration] = Encoder.encodeString.contramap[Duration](_.toString)

  implicit val _mimeTypeDec: Decoder[MimeType] = Decoder.decodeString.map(s => MimeType.parse(s).get)
  implicit val _mimeTypeEnc: Encoder[MimeType] = Encoder.encodeString.contramap[MimeType](_.asString)

  implicit val _sizeDec: Decoder[Size] = Decoder.decodeLong.map(b => Bytes(b))
  implicit val _sizeEnc: Encoder[Size] = Encoder.encodeLong.contramap[Size](_.toBytes)

  implicit val _uploadDec: Decoder[Upload] = deriveDecoder[Upload]
  implicit val _uploadEnc: Encoder[Upload] = deriveEncoder[UploadWeb].
    contramap(UploadWeb.fromUpload)

  implicit val _fileMetaDec: Decoder[FileMeta] = deriveDecoder[FileMeta]
  implicit val _fileMetaEnc: Encoder[FileMeta] = deriveEncoder[FileMeta]

  implicit val _uploadInfoFileDec: Decoder[UploadInfo.File] = deriveDecoder[UploadInfo.File]
  implicit val _uploadInfoFileEnc: Encoder[UploadInfo.File] = deriveEncoder[UploadInfo.File]

  implicit val _uploadInfoDec: Decoder[UploadInfo] = deriveDecoder[UploadInfo]
  implicit val _uploadInfoEnc: Encoder[UploadInfo] = deriveEncoder[UploadInfo]

  implicit val _uploadMetaDec: Decoder[UploadCreate] = deriveDecoder[UploadCreate]
  implicit val _uploadMetaEnc: Encoder[UploadCreate] = deriveEncoder[UploadCreate]

}
