package sharry.backend.share

import cats.data.OptionT
import cats.effect.ConcurrentEffect
import cats.effect.Effect
import cats.effect.Sync
import cats.implicits._
import fs2.Stream

import sharry.common._
import sharry.common.syntax.all._
import sharry.store.Store
import sharry.store.doobie.DoobieMeta._
import sharry.store.doobie._
import sharry.store.records.RAccount
import sharry.store.records.RAlias
import sharry.store.records.RPublishShare
import sharry.store.records.RShare
import sharry.store.records.RShareFile

import bitpeace.Mimetype
import doobie._
import doobie.implicits._
import org.log4s.getLogger
import sharry.store.records.RAliasMember

object Queries {
  private[this] val logger = getLogger

  object FileMetaCols {
    val id        = Column("id")
    val timestamp = Column("timestamp")
    val mimetype  = Column("mimetype")
    val length    = Column("length")
    val checksum  = Column("checksum")
    val chunks    = Column("chunks")
    val chunksize = Column("chunksize")

    val all   = List(id, timestamp, mimetype, length, checksum, chunks, chunksize)
    val table = fr"filemeta"
  }
  object FileChunkCols {
    val table       = fr"filechunk"
    val fileId      = Column("fileId")
    val chunkLength = Column("chunkLength")
    val chunkNr     = Column("chunkNr")
  }

  case class FileDesc(
      metaId: Ident,
      name: Option[String],
      mime: String,
      length: ByteSize
  ) {
    def mimeType: Mimetype =
      Mimetype.parse(mime).fold(throw _, identity)
  }

  def fileDesc(shareFileId: Ident): ConnectionIO[Option[FileDesc]] = {
    val SF = RShareFile.Columns
    val cols =
      Seq(
        "m" :: FileMetaCols.id,
        "f" :: SF.filename,
        "m" :: FileMetaCols.mimetype,
        "m" :: FileMetaCols.length
      )
    val from = RShareFile.table ++ fr"f INNER JOIN filemeta m ON f.file_id = m.id"
    Sql.selectSimple(cols, from, ("f" :: SF.id).is(shareFileId)).query[FileDesc].option
  }

  private def fileDataFragment0(where: Fragment): Fragment = {
    val fId   = "f" :: RShareFile.Columns.id
    val fFile = "f" :: RShareFile.Columns.fileId
    val mId   = "m" :: FileMetaCols.id

    val cols = Seq(
      fId,
      "f" :: RShareFile.Columns.shareId,
      "m" :: FileMetaCols.id,
      "f" :: RShareFile.Columns.filename,
      "m" :: FileMetaCols.mimetype,
      "m" :: FileMetaCols.length,
      "m" :: FileMetaCols.checksum,
      "m" :: FileMetaCols.chunks,
      "m" :: FileMetaCols.chunksize,
      "f" :: RShareFile.Columns.created,
      "f" :: RShareFile.Columns.realSize
    )
    val from = RShareFile.table ++ fr"f INNER JOIN filemeta m ON" ++ mId.is(fFile)

    Sql.selectSimple(cols, from, where)
  }

  private def fileDataShareFileFragment(shareFileId: Ident): Fragment = {
    val fId = "f" :: RShareFile.Columns.id
    fileDataFragment0(fId.is(shareFileId))
  }

  private def fileDataShareFragment(shareId: Ident): Fragment = {
    val fShare = "f" :: RShareFile.Columns.shareId
    fileDataFragment0(fShare.is(shareId))
  }

  def fileData(shareFileId: Ident): ConnectionIO[Option[FileData]] = {
    val q = fileDataShareFileFragment(shareFileId)
    q.query[FileData].option
  }

  def shareSize(shareId: Ident): ConnectionIO[ByteSize] = {
    val fShare = "f" :: RShareFile.Columns.shareId
    val fSize  = "f" :: RShareFile.Columns.realSize

    val qSize = Sql.selectSimple(
      fr"COALESCE(SUM(" ++ fSize.f ++ fr"), 0) as size",
      RShareFile.table ++ fr"f",
      fShare.is(shareId)
    )

    qSize
      .query[ByteSize]
      .option
      .map(_.getOrElse(ByteSize.zero))
  }

  def checkShare(share: Ident, accId: AccountId): ConnectionIO[Option[Unit]] = {
    val sId      = "s" :: RShare.Columns.id
    val sAlias   = "s" :: RShare.Columns.aliasId
    val sAccount = "s" :: RShare.Columns.accountId

    val from = RShare.table ++ fr"s"

    val cond = Seq(
      sId.is(share),
      Sql.or(sAccount.is(accId.id), sAlias.in(aliasMemberOf(accId.id)))
    ) ++
      accId.alias.map(alias => Seq(sAlias.is(alias))).getOrElse(Seq.empty)

    Sql
      .selectSimple(Seq(sId), from, Sql.and(cond))
      .query[Ident]
      .map(_ => ())
      .option
  }

  def checkFilePublish(
      sharePublic: Ident,
      fileId: Ident
  ): ConnectionIO[Option[Option[Password]]] = {
    val sId     = "s" :: RShare.Columns.id
    val sPass   = "s" :: RShare.Columns.password
    val pShare  = "p" :: RPublishShare.Columns.shareId
    val pId     = "p" :: RPublishShare.Columns.id
    val fShare  = "f" :: RShareFile.Columns.shareId
    val fId     = "f" :: RShareFile.Columns.id
    val pEnable = "p" :: RPublishShare.Columns.enabled
    val pUntil  = "p" :: RPublishShare.Columns.publishUntil

    val from = RPublishShare.table ++ fr"p INNER JOIN" ++
      RShare.table ++ fr"s ON" ++ pShare.is(sId) ++
      fr"INNER JOIN" ++ RShareFile.table ++ fr"f ON" ++ fShare.is(sId)

    def cond(now: Timestamp) =
      Seq(pId.is(sharePublic), fId.is(fileId), pEnable.is(true), pUntil.isGt(now))

    for {
      now <- Timestamp.current[ConnectionIO]
      q <-
        Sql
          .selectSimple(Seq(sPass), from, Sql.and(cond(now)))
          .query[Option[Password]]
          .option
    } yield q
  }

  def checkFile(fileId: Ident, accId: AccountId): ConnectionIO[Option[Unit]] = {
    val sId      = "s" :: RShare.Columns.id
    val sAccount = "s" :: RShare.Columns.accountId
    val sAlias   = "s" :: RShare.Columns.aliasId
    val fShare   = "f" :: RShareFile.Columns.shareId
    val fId      = "f" :: RShareFile.Columns.id

    val from = RShare.table ++ fr"s" ++
      fr"INNER JOIN" ++ RShareFile.table ++ fr"f ON" ++ fShare.is(sId)
    val cond = Seq(
      fId.is(fileId),
      Sql.or(sAccount.is(accId.id), sAlias.in(aliasMemberOf(accId.id)))
    ) ++
      accId.alias.map(alias => Seq(sAlias.is(alias))).getOrElse(Seq.empty)

    Sql
      .selectSimple(Seq(fId), from, Sql.and(cond))
      .query[Ident]
      .map(_ => ())
      .option
  }

  private def fileSummary: Fragment = {
    val fileId = "m" :: FileMetaCols.id
    val size   = "m" :: FileMetaCols.length
    val rFile  = "r" :: RShareFile.Columns.fileId
    val rShare = "r" :: RShareFile.Columns.shareId

    val cols =
      rShare.f ++ fr"as fshare, COUNT(" ++ fileId.f ++ fr") as files, SUM(" ++ size.f ++ fr") as size"
    val table = RShareFile.table ++ fr"r" ++
      fr"INNER JOIN filemeta m ON" ++ rFile.is(fileId) ++
      fr"GROUP BY fshare"

    Sql.selectSimple(cols, table, Fragment.empty)
  }

  private def aliasMemberOf(accId: Ident) =
    RAliasMember.aliasMemberOf(accId)

  def findShares(q: String, accId: AccountId): Stream[ConnectionIO, ShareItem] = {
    val nfiles     = Column("files")
    val nsize      = Column("size")
    val shareId    = "s" :: RShare.Columns.id
    val account    = "s" :: RShare.Columns.accountId
    val pShare     = "p" :: RPublishShare.Columns.shareId
    val name       = "s" :: RShare.Columns.name
    val sid        = "s" :: RShare.Columns.id
    val aliasName  = "a" :: RAlias.Columns.name
    val aliasId    = "a" :: RAlias.Columns.id
    val shareAlias = "s" :: RShare.Columns.aliasId
    val created    = "s" :: RShare.Columns.created
    val cols = RShare.Columns.all.map("s" :: _).map(_.f) ++ Seq(
      ("p" :: RPublishShare.Columns.enabled).f,
      ("p" :: RPublishShare.Columns.publishUntil).f,
      aliasId.f, aliasName.f,
      fr"COALESCE(" ++ ("f" :: nfiles).f ++ fr", 0)",
      fr"COALESCE(" ++ ("f" :: nsize).f ++ fr", 0)"
    )

    val from = RShare.table ++ fr"s" ++
      fr"LEFT OUTER JOIN" ++ RPublishShare.table ++ fr"p ON" ++ pShare.is(shareId) ++
      fr"LEFT OUTER JOIN" ++ RAlias.table ++ fr"a ON" ++ aliasId.is(shareAlias) ++
      fr"LEFT OUTER JOIN (" ++ fileSummary ++ fr") as f ON fshare = s.id"

    val qs = s"%$q%"
    val frag = Sql.selectSimple(
      Sql.commas(cols),
      from,
      Sql.and(
        Sql.or(account.is(accId.id), shareAlias.in(aliasMemberOf(accId.id))),
        Sql.or(name.like(qs), sid.like(qs), aliasName.like(qs))
      )
    ) ++ fr"ORDER BY" ++ created.f ++ fr"DESC"
    logger.trace(s"$frag")
    frag.query[ShareItem].stream
  }

  def shareDetail(shareId: ShareId): OptionT[ConnectionIO, ShareDetail] = {
    val account   = "s" :: RShare.Columns.accountId
    val sId       = "s" :: RShare.Columns.id
    val sAlias    = "s" :: RShare.Columns.aliasId
    val sMaxViews = "s" :: RShare.Columns.maxViews
    val pShare    = "p" :: RPublishShare.Columns.shareId
    val pEnable   = "p" :: RPublishShare.Columns.enabled
    val pUntil    = "p" :: RPublishShare.Columns.publishUntil
    val pId       = "p" :: RPublishShare.Columns.id
    val pViews    = "p" :: RPublishShare.Columns.views
    val aId       = "a" :: RAlias.Columns.id

    val cols = RShare.Columns.all.map("s" :: _) ++
      RPublishShare.Columns.all.map("p" :: _) ++
      RAlias.Columns.all.map("a" :: _)

    val from = RShare.table ++ fr"s" ++
      fr"LEFT OUTER JOIN" ++ RPublishShare.table ++ fr"p ON" ++ pShare.is(sId) ++
      fr"LEFT OUTER JOIN" ++ RAlias.table ++ fr"a ON" ++ sAlias.is(aId)

    def cond(now: Timestamp) =
      shareId.fold(
        pub =>
          Sql.and(
            pId.is(pub.id),
            pEnable.is(true),
            pUntil.isGt(now),
            sMaxViews.isGt(pViews)
          ),
        priv =>
          Sql.and(
            Sql
              .or(account.is(priv.account.id), sAlias.in(aliasMemberOf(priv.account.id))),
            sId.is(priv.id)
          )
      )

    def qDetail(now: Timestamp) = Sql.selectSimple(cols, from, cond(now))
    def qFiles(share: Ident) =
      fileDataShareFragment(share)

    for {
      now <- OptionT.liftF(Timestamp.current[ConnectionIO])
      detail <- OptionT(
        qDetail(now).query[(RShare, Option[RPublishShare], Option[RAlias])].option
      )
      files <- OptionT.liftF(qFiles(detail._1.id).query[FileData].to[List])
    } yield ShareDetail(detail._1, detail._2, detail._3, files)
  }

  def countPublishAccess(shareId: ShareId): ConnectionIO[Unit] =
    shareId match {
      case ShareId.PrivateId(_, _) =>
        Sync[ConnectionIO].pure(())

      case ShareId.PublicId(id) =>
        val pId         = RPublishShare.Columns.id
        val pViews      = RPublishShare.Columns.views
        val pLastAccess = RPublishShare.Columns.lastAccess

        for {
          now <- Timestamp.current[ConnectionIO]
          _ <-
            Sql
              .updateRow(
                RPublishShare.table,
                pId.is(id),
                Sql.commas(
                  pViews.increment(1),
                  pLastAccess.setTo(now)
                )
              )
              .update
              .run
        } yield ()
    }

  def findExpired(point: Timestamp): Stream[ConnectionIO, (RShare, RAccount)] = {
    val pShare  = "p" :: RPublishShare.Columns.shareId
    val pUntil  = "p" :: RPublishShare.Columns.publishUntil
    val pEnable = "p" :: RPublishShare.Columns.enabled

    val aId = "a" :: RAccount.Columns.id

    val sId        = "s" :: RShare.Columns.id
    val sAccountId = "s" :: RShare.Columns.accountId

    val cols = RShare.Columns.all.map("s" :: _).map(_.f) ++ RAccount.Columns.all
      .map("a" :: _)
      .map(_.f)
    val from = RPublishShare.table ++ fr"p" ++
      fr"LEFT JOIN" ++ RShare.table ++ fr"s ON" ++ pShare.is(sId) ++
      fr"LEFT JOIN" ++ RAccount.table ++ fr"a ON" ++ sAccountId.is(aId)

    val frag = Sql.selectSimple(
      Sql.commas(cols),
      from,
      Sql.and(pEnable.is(true), pUntil.isLt(point))
    )
    logger.trace(s"$frag")
    frag.query[(RShare, RAccount)].stream
  }

  def findOrphanedFiles: Stream[ConnectionIO, Ident] = {
    val fId   = "f" :: RShareFile.Columns.id
    val fFile = "f" :: RShareFile.Columns.fileId
    val mId   = "m" :: FileMetaCols.id

    val from =
      FileMetaCols.table ++ fr"m LEFT OUTER JOIN" ++ RShareFile.table ++ fr"f ON" ++ fFile
        .is(mId)
    val q = Sql.selectSimple(Seq(mId), from, fId.isNull)
    logger.trace(s"findOrphaned: $q")
    q.query[Ident].stream
  }

  def deleteFile[F[_]: Effect](store: Store[F])(fileMetaId: Ident) = {
    def deleteChunk(fid: Ident, chunk: Int): F[Int] =
      store
        .transact(
          Sql
            .deleteFrom(
              FileChunkCols.table,
              Sql.and(FileChunkCols.fileId.is(fid), FileChunkCols.chunkNr.is(chunk))
            )
            .update
            .run
        )

    // When deleting large files, doing it in one transaction may blow
    // memory. It is not important to be all-or-nothing, so here each
    // chunk is deleted in one tx. This is slow, of course, but can be
    // moved to a background thread. The cleanup job also detects
    // orphaned files and removes them.
    def deleteFileData(fid: Ident): F[Unit] =
      Stream
        .iterate(0)(_ + 1)
        .covary[F]
        .evalMap(n => deleteChunk(fid, n))
        .takeWhile(_ > 0)
        .compile
        .drain

    def deleteFileMeta(fid: Ident): F[Int] =
      store.transact(for {
        a <- RShareFile.deleteByFileId(fid)
        c <- Sql.deleteFrom(FileMetaCols.table, FileMetaCols.id.is(fid)).update.run
      } yield a + c)

    deleteFileData(fileMetaId) *> deleteFileMeta(fileMetaId)
  }

  def deleteShare[F[_]: ConcurrentEffect](share: Ident, background: Boolean)(
      store: Store[F]
  ): F[Unit] = {
    val rFileId  = RShareFile.Columns.fileId
    val rShareId = RShareFile.Columns.shareId

    def allFileIds: F[Vector[Ident]] =
      store.transact(
        Sql
          .selectSimple(Seq(rFileId), RShareFile.table, rShareId.is(share))
          .query[Ident]
          .to[Vector]
      )

    def deleteAllFiles(ids: Vector[Ident]) =
      ids.traverse(deleteFile(store)) *> logger.fdebug[F](
        s"All files of share ${share.id} deleted"
      )

    for {
      _    <- logger.fdebug[F](s"Going to delete share: ${share.id}")
      fids <- allFileIds
      _    <- store.transact(RShare.delete(share))
      _ <-
        if (background) ConcurrentEffect[F].start(deleteAllFiles(fids))
        else deleteAllFiles(fids)
    } yield ()
  }

  def setDescription(share: Ident, value: String): ConnectionIO[Int] =
    Sql
      .updateRow(
        RShare.table,
        RShare.Columns.id.is(share),
        RShare.Columns.description.setTo(value)
      )
      .update
      .run

  def setName(share: Ident, value: Option[String]): ConnectionIO[Int] =
    Sql
      .updateRow(
        RShare.table,
        RShare.Columns.id.is(share),
        RShare.Columns.name.setTo(value)
      )
      .update
      .run

  def setValidity(share: Ident, value: Duration): ConnectionIO[Int] =
    for {
      n <-
        Sql
          .updateRow(
            RShare.table,
            RShare.Columns.id.is(share),
            RShare.Columns.validity.setTo(value)
          )
          .update
          .run
      k <- RPublishShare.updateValidityTime(share, value)
    } yield n + k

  def setMaxViews(share: Ident, value: Int): ConnectionIO[Int] =
    Sql
      .updateRow(
        RShare.table,
        RShare.Columns.id.is(share),
        RShare.Columns.maxViews.setTo(value)
      )
      .update
      .run

  def setPassword(share: Ident, value: Option[Password]): ConnectionIO[Int] =
    Sql
      .updateRow(
        RShare.table,
        RShare.Columns.id.is(share),
        RShare.Columns.password.setTo(value)
      )
      .update
      .run
}
