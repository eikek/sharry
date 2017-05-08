package sharry.store.data

case class UploadInfo(
  upload: Upload
    , files: Seq[UploadInfo.File]
)

object UploadInfo {

  case class File(
    meta: FileMeta
      , filename: String
  )
}
