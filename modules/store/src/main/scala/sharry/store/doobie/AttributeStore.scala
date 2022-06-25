package sharry.store.doobie

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import sharry.common._
import sharry.store.records.RFileMeta

import binny._
import doobie._
import doobie.implicits._
import scodec.bits.ByteVector

final private[store] class AttributeStore[F[_]: Sync](xa: Transactor[F]) {

  def saveAttr(id: BinaryId, attrs: F[BinaryAttributes]): F[Unit] =
    for {
      now <- Timestamp.current[F]
      a <- attrs
      fm = RFileMeta(
        Ident.unsafe(id.id),
        now,
        a.contentType.contentType,
        ByteSize(a.length),
        a.sha256
      )
      _ <- saveMeta(fm)
    } yield ()

  def deleteAttr(id: BinaryId): F[Boolean] =
    RFileMeta.delete(Ident.unsafe(id.id)).transact(xa).map(_ > 0)

  def findAttr(id: BinaryId): OptionT[F, BinaryAttributes] =
    findMeta(id).map(fm =>
      BinaryAttributes(fm.checksum, SimpleContentType(fm.mimetype), fm.length.bytes)
    )

  def findMeta(id: BinaryId): OptionT[F, RFileMeta] =
    OptionT(RFileMeta.findById(Ident.unsafe(id.id)).transact(xa))

  def saveMeta(fm: RFileMeta): F[Unit] =
    RFileMeta.upsert(fm).transact(xa).void

  def updateCreated(id: BinaryId, created: Timestamp): F[Unit] =
    RFileMeta.updateCreated(Ident.unsafe(id.id), created).transact(xa).void

  def updateChecksum(id: Ident, checksum: ByteVector): F[Unit] =
    RFileMeta.updateChecksum(id, checksum).transact(xa).void
}

object AttributeStore {

  def apply[F[_]: Sync](xa: Transactor[F]): AttributeStore[F] =
    new AttributeStore[F](xa)
}
