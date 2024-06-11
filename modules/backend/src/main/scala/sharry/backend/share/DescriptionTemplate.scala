package sharry.backend.share

import sharry.backend.mustache.YamuscaCommon
import sharry.common.*

import yamusca.derive.*
import yamusca.implicits.*
import yamusca.imports.*

final class DescriptionTemplate(sd: ShareDetail) {

  def rendered(baseUri: LenientUri): Option[String] =
    sd.share.description.map(process(baseUri))

  def process(baseUri: LenientUri)(desc: String): String =
    mustache
      .parse(desc)
      .map(DescriptionTemplate.ShareContext(sd, baseUri).render)
      .getOrElse(desc)

}
object DescriptionTemplate {

  def apply(sd: ShareDetail): DescriptionTemplate =
    new DescriptionTemplate(sd)

  case class ShareContext(
      key: Ident,
      openKey: Option[Ident],
      files: Seq[FileInfo],
      filename: Map[String, FileInfo],
      file: Map[Int, FileInfo]
  )

  object ShareContext extends YamuscaCommon {

    def apply(sd: ShareDetail, baseUri: LenientUri): ShareContext =
      ShareContext(
        sd.share.id,
        sd.published.map(_.id),
        sd.files.map(f => FileInfo(baseUri)(f)),
        sd.files
          .map(f => FileInfo(baseUri)(f).byName)
          .foldLeft(Map.empty[String, FileInfo])(_ ++ _),
        sd.files.map(FileInfo(baseUri)).zipWithIndex.map(_.swap).toMap
      )

    implicit val contextConv: ValueConverter[ShareContext] =
      deriveValueConverter[ShareContext]
  }

  case class FileInfo(
      id: Ident,
      name: Option[String],
      mimetype: String,
      length: ByteSize,
      size: String,
      checksum: String,
      url: LenientUri
  ) {

    def byName: Map[String, FileInfo] =
      name match {
        case Some(n) =>
          Map(n.replace(".", "") -> this)
        case None =>
          Map.empty
      }
  }

  object FileInfo extends YamuscaCommon {

    def apply(baseUri: LenientUri)(fd: FileData): FileInfo =
      FileInfo(
        fd.id,
        fd.name,
        fd.mimetype,
        fd.length,
        fd.length.toHuman,
        fd.checksum,
        baseUri / fd.id.id
      )

    implicit val fileInfoConverter: ValueConverter[FileInfo] =
      deriveValueConverter[FileInfo]
  }
}
