package sharry.store.data

import io.circe._, io.circe.generic.semiauto._

case class UploadInfo(
  upload: Upload
    , files: Seq[UploadInfo.File]
)

object UploadInfo {

  case class File(
    meta: FileMeta
      , filename: String
      , clientFileId: String
  )

  object File {
    implicit val _uploadInfoFileDec: Decoder[UploadInfo.File] = deriveDecoder[UploadInfo.File]
    implicit val _uploadInfoFileEnc: Encoder[UploadInfo.File] = deriveEncoder[UploadInfo.File]
  }

  implicit val _uploadInfoDec: Decoder[UploadInfo] = deriveDecoder[UploadInfo]
  implicit val _uploadInfoEnc: Encoder[UploadInfo] = deriveEncoder[UploadInfo]
}
