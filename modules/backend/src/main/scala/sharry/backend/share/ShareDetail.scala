package sharry.backend.share

import sharry.store.records._
import sharry.common.LenientUri

case class ShareDetail(
    share: RShare,
    published: Option[RPublishShare],
    alias: Option[RAlias],
    files: Seq[FileData]
) {

  def descProcessed(baseUri: LenientUri): Option[String] =
    DescriptionTemplate(this).rendered(baseUri)
}
