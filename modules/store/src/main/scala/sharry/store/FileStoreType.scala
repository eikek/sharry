package sharry.store

import cats.data.NonEmptyList

sealed trait FileStoreType { self: Product =>
  def name: String =
    productPrefix.toLowerCase
}
object FileStoreType {
  case object DefaultDatabase extends FileStoreType

  case object S3 extends FileStoreType

  case object FileSystem extends FileStoreType

  val all: NonEmptyList[FileStoreType] =
    NonEmptyList.of(DefaultDatabase, S3, FileSystem)

  def fromString(str: String): Either[String, FileStoreType] =
    val sn = str.replaceAll("[-_]", "") // allow kebab- and snake-case
    all
      .find(e => e.name.equalsIgnoreCase(sn) || e.name.equalsIgnoreCase(str))
      .toRight(s"Invalid file store type: $str")

  def unsafeFromString(str: String): FileStoreType =
    fromString(str).fold(sys.error, identity)
}
