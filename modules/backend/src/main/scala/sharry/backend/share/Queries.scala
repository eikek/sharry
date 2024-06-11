package sharry.backend.share

import cats.data.OptionT
import cats.effect.*
import cats.syntax.all.*
import fs2.Stream

import sharry.common.*
import sharry.store.Store
import sharry.store.doobie.*
import sharry.store.doobie.DoobieMeta.*
import sharry.store.records.*

import doobie.*
import doobie.implicits.*

object Queries {
  val logger = sharry.logging.getLogger[ConnectionIO]

  object FileChunkCols {
    val table = fr"filechunk"
    val fileId = Column("file_id")
    val chunkLength = Column("chunk_len")
    val chunkNr = Column("chunk_nr")
  }

  case class FileDesc(
      metaId: Ident,
      name: Option[String],
      mime: String,
      length: ByteSize
  )

  def fileDesc(shareFileId: Ident): ConnectionIO[Option[FileDesc]] = {
    val mFileId = "m" :: RFileMeta.Columns.id
    val fFileId = "f" :: RShareFile.Columns.fileId
    val SF = RShareFile.Columns
    val cols =
      Seq(
        mFileId,
        "f" :: SF.filename,
        "m" :: RFileMeta.Columns.mimetype,
        "m" :: RFileMeta.Columns.length
      )
    val from =
      RShareFile.table ++ fr"f INNER JOIN " ++ RFileMeta.table ++
        fr" m ON" ++ fFileId.is(mFileId)
    Sql.selectSimple(cols, from, ("f" :: SF.id).is(shareFileId)).query[FileDesc].option
  }

  private def fileDataFragment0(where: Fragment): Fragment = {
    val fId = "f" :: RShareFile.Columns.id
    val fFile = "f" :: RShareFile.Columns.fileId
    val mId = "m" :: RFileMeta.Columns.id

    val cols = Seq(
      fId,
      "f" :: RShareFile.Columns.shareId,
      "m" :: RFileMeta.Columns.id,
      "f" :: RShareFile.Columns.filename,
      "m" :: RFileMeta.Columns.mimetype,
      "m" :: RFileMeta.Columns.length,
      "m" :: RFileMeta.Columns.checksum,
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
    val fSize = "f" :: RShareFile.Columns.realSize

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
    val sId = "s" :: RShare.Columns.id
    val sAlias = "s" :: RShare.Columns.aliasId
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
    val sId = "s" :: RShare.Columns.id
    val sPass = "s" :: RShare.Columns.password
    val pShare = "p" :: RPublishShare.Columns.shareId
    val pId = "p" :: RPublishShare.Columns.id
    val fShare = "f" :: RShareFile.Columns.shareId
    val fId = "f" :: RShareFile.Columns.id
    val pEnable = "p" :: RPublishShare.Columns.enabled
    val pUntil = "p" :: RPublishShare.Columns.publishUntil

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
    val sId = "s" :: RShare.Columns.id
    val sAccount = "s" :: RShare.Columns.accountId
    val sAlias = "s" :: RShare.Columns.aliasId
    val fShare = "f" :: RShareFile.Columns.shareId
    val fId = "f" :: RShareFile.Columns.id

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
    val fileId = "m" :: RFileMeta.Columns.id
    val size = "m" :: RFileMeta.Columns.length
    val rFile = "r" :: RShareFile.Columns.fileId
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
    val nfiles = Column("files")
    val nsize = Column("size")
    val shareId = "s" :: RShare.Columns.id
    val account = "s" :: RShare.Columns.accountId
    val pShare = "p" :: RPublishShare.Columns.shareId
    val name = "s" :: RShare.Columns.name
    val sid = "s" :: RShare.Columns.id
    val aliasName = "a" :: RAlias.Columns.name
    val aliasId = "a" :: RAlias.Columns.id
    val shareAlias = "s" :: RShare.Columns.aliasId
    val created = "s" :: RShare.Columns.created
    val description = "s" :: RShare.Columns.description
    val cols = RShare.Columns.all.map("s" :: _).map(_.f) ++ Seq(
      ("p" :: RPublishShare.Columns.enabled).f,
      ("p" :: RPublishShare.Columns.publishUntil).f,
      aliasId.f,
      aliasName.f,
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
        Sql.or(name.like(qs), sid.like(qs), aliasName.like(qs), description.like(qs))
      )
    ) ++ fr"ORDER BY" ++ created.f ++ fr"DESC"
    logger.stream.trace(s"$frag").drain ++
      frag.query[ShareItem].stream
  }

  def shareDetail(shareId: ShareId): OptionT[ConnectionIO, ShareDetail] = {
    val account = "s" :: RShare.Columns.accountId
    val sId = "s" :: RShare.Columns.id
    val sAlias = "s" :: RShare.Columns.aliasId
    val sMaxViews = "s" :: RShare.Columns.maxViews
    val pShare = "p" :: RPublishShare.Columns.shareId
    val pEnable = "p" :: RPublishShare.Columns.enabled
    val pUntil = "p" :: RPublishShare.Columns.publishUntil
    val pId = "p" :: RPublishShare.Columns.id
    val pViews = "p" :: RPublishShare.Columns.views
    val aId = "a" :: RAlias.Columns.id

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
        val pId = RPublishShare.Columns.id
        val pViews = RPublishShare.Columns.views
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
    val pShare = "p" :: RPublishShare.Columns.shareId
    val pUntil = "p" :: RPublishShare.Columns.publishUntil
    val pEnable = "p" :: RPublishShare.Columns.enabled

    val aId = "a" :: RAccount.Columns.id

    val sId = "s" :: RShare.Columns.id
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
    logger.stream.trace(s"$frag").drain ++
      frag.query[(RShare, RAccount)].stream
  }

  def findOrphanedFiles: Stream[ConnectionIO, Ident] = {
    val fId = "f" :: RShareFile.Columns.id
    val fFile = "f" :: RShareFile.Columns.fileId
    val mId = "m" :: RFileMeta.Columns.id

    val from =
      RFileMeta.table ++ fr"m LEFT OUTER JOIN" ++ RShareFile.table ++ fr"f ON" ++ fFile
        .is(mId)
    val q = Sql.selectSimple(Seq(mId), from, fId.isNull)
    logger.stream.trace(s"findOrphaned: $q").drain ++
      q.query[Ident].stream
  }

  def deleteFile[F[_]: Async](store: Store[F])(fileMetaId: Ident) = {
    val deleteFileData =
      store.fileStore.delete(fileMetaId)

    def deleteFileMeta(fid: Ident): F[Int] =
      store.transact(for {
        a <- RShareFile.deleteByFileId(fid)
        c <- Sql.deleteFrom(RFileMeta.table, RFileMeta.Columns.id.is(fid)).update.run
      } yield a + c)

    deleteFileData *> deleteFileMeta(fileMetaId)
  }

  def deleteShare[F[_]: Async](share: Ident, background: Boolean)(
      store: Store[F]
  ): F[Unit] = {
    val rFileId = RShareFile.Columns.fileId
    val rShareId = RShareFile.Columns.shareId
    val log = sharry.logging.getLogger[F]

    def allFileIds: F[Vector[Ident]] =
      store.transact(
        Sql
          .selectSimple(Seq(rFileId), RShareFile.table, rShareId.is(share))
          .query[Ident]
          .to[Vector]
      )

    def deleteAllFiles(ids: Vector[Ident]) =
      ids.traverse(deleteFile(store)) *> log.debug(
        s"All files of share ${share.id} deleted"
      )

    for {
      _ <- log.debug(s"Going to delete share: ${share.id}")
      fids <- allFileIds
      _ <- store.transact(RShare.delete(share))
      _ <-
        if (background) Async[F].start(deleteAllFiles(fids)).void
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
