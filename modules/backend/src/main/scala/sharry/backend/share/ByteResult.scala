package sharry.backend.share

import cats.data.OptionT
import cats.effect._

import sharry.common.Ident
import sharry.store.Store
import sharry.store.records.{RFileMeta, RShareFile}

import binny.ByteRange

object ByteResult {

  def load[F[_]: Async](
      store: Store[F]
  )(fileId: Ident, range: ByteRange): OptionT[F, FileRange[F]] =
    for {
      meta <- loadMeta(fileId, store)
      data <- store.fileStore.findBinary(meta._2.id, range)
    } yield FileRange(meta._1, meta._2, data)

  // TODO use one query?
  private def loadMeta[F[_]: Async](
      fileId: Ident,
      store: Store[F]
  ): OptionT[F, (RShareFile, RFileMeta)] =
    for {
      rf <- OptionT(store.transact(RShareFile.findById(fileId)))
      fm <- store.fileStore.findMeta(rf.fileId)
    } yield (rf, fm)

}
