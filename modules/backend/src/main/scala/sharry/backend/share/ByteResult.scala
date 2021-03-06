package sharry.backend.share

import cats.data.OptionT
import cats.effect._
import fs2.Stream

import sharry.common.Ident
import sharry.store.Store
import sharry.store.records.RShareFile

import bitpeace.FileMeta
import bitpeace.{Bitpeace, RangeDef}

object ByteResult {

  def loadFileData[F[_]](
      bitpeace: Bitpeace[F],
      id: String,
      range: RangeDef
  ): Stream[F, Byte] =
    bitpeace.get(id).unNoneTerminate.through(bitpeace.fetchData(range))

  def load[F[_]: Async](
      store: Store[F]
  )(fileId: Ident, range: RangeDef): OptionT[F, FileRange[F]] =
    for {
      meta <- loadMeta(fileId, store)
      data <- OptionT.pure(Stream.emit(meta._2).through(store.bitpeace.fetchData(range)))
    } yield FileRange(meta._1, meta._2, data)

  // impl. note: bitpeace uses for filemeta's timestamp column a different mapping, so
  // it's complicated to create a single query with doobie. Using to two queries.
  private def loadMeta[F[_]: Async](
      fileId: Ident,
      store: Store[F]
  ): OptionT[F, (RShareFile, FileMeta)] =
    for {
      rf <- OptionT(store.transact(RShareFile.findById(fileId)))
      fm <- OptionT(store.bitpeace.get(rf.fileId.id).unNoneTerminate.compile.last)
    } yield (rf, fm)

}
