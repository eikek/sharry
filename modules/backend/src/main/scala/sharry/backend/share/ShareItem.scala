package sharry.backend.share

import sharry.common.ByteSize
import sharry.common.Timestamp
import sharry.store.records.RShare

case class ShareItem(
    share: RShare,
    published: Option[ShareItem.PublishSummary],
    aliasName: Option[String],
    files: ShareItem.FileSummary
)

object ShareItem {

  case class FileSummary(count: Int, size: ByteSize)

  case class PublishSummary(enabled: Boolean, publishUntil: Timestamp)
}
