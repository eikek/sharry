package sharry.backend.share

import sharry.common._
import sharry.store.records.RShare

case class ShareItem(
    share: RShare,
    published: Option[ShareItem.PublishSummary],
    alias: Option[ShareItem.AliasInfo],
    files: ShareItem.FileSummary
)

object ShareItem {

  case class FileSummary(count: Int, size: ByteSize)

  case class PublishSummary(enabled: Boolean, publishUntil: Timestamp)

  case class AliasInfo(id: Ident, name: String)
}
