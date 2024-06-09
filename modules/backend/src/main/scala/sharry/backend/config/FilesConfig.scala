package sharry.backend.config

import cats.data.{Validated, ValidatedNec}
import cats.syntax.all.*

import sharry.common.Ident
import sharry.store.FileStoreConfig

case class FilesConfig(
    defaultStore: Ident,
    stores: Map[Ident, FileStoreConfig],
    copyFiles: CopyFilesConfig
) {

  val enabledStores: Map[Ident, FileStoreConfig] =
    stores.view.filter(_._2.enabled).toMap

  def defaultStoreConfig: FileStoreConfig =
    enabledStores.getOrElse(
      defaultStore,
      sys.error(s"Store '${defaultStore.id}' not found. Is it enabled?")
    )

  def validate: ValidatedNec[String, FilesConfig] = {
    val storesEmpty =
      if (enabledStores.isEmpty)
        Validated.invalidNec(
          "No file stores defined! Make sure at least one enabled store is present."
        )
      else Validated.validNec(())

    val defaultStorePresent =
      enabledStores.get(defaultStore) match {
        case Some(_) => Validated.validNec(())
        case None =>
          Validated.invalidNec(s"Default file store not present: ${defaultStore}")
      }

    val validCopyStores =
      if (!copyFiles.enable) Validated.validNec(())
      else {
        val exist = enabledStores.contains(copyFiles.source) &&
          enabledStores.contains(copyFiles.target)
        if (exist) Validated.validNec(())
        else
          Validated.invalidNec(
            s"The source or target name for the copy-files section doesn't exist in the list of enabled file stores."
          )
      }

    (storesEmpty |+| defaultStorePresent |+| validCopyStores |+| copyFiles.validate)
      .map(_ => this)
  }
}
