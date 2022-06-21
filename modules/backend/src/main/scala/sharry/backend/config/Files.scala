package sharry.backend.config

import cats.data.{Validated, ValidatedNec}
import cats.syntax.all._

import sharry.common.Ident
import sharry.store.FileStoreConfig

case class Files(defaultStore: Ident, stores: Map[Ident, FileStoreConfig]) {

  val enabledStores: Map[Ident, FileStoreConfig] =
    stores.view.filter(_._2.enabled).toMap

  def defaultStoreConfig: FileStoreConfig =
    enabledStores.getOrElse(
      defaultStore,
      sys.error(s"Store '${defaultStore.id}' not found. Is it enabled?")
    )

  def validate: ValidatedNec[String, Files] = {
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

    (storesEmpty |+| defaultStorePresent).map(_ => this)
  }
}
