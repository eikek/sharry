package sharry.store.migrate

import fs2.Stream
import doobie._
import doobie.implicits._
import cats.implicits._
import cats.effect._
import org.log4s.getLogger
import scala.concurrent.ExecutionContext

import sharry.common._
import sharry.common.syntax.all._
import sharry.store.Store
import sharry.store.JdbcConfig
import sharry.store.records._
import sharry.store.doobie.Sql
import sharry.store.doobie.DoobieMeta._
import cats.data.OptionT

final class MigrateFrom06[F[_]: Effect: ContextShift](
    cfg: JdbcConfig,
    store: Store[F],
    blocker: Blocker
) {
  private[this] val logger = getLogger

  def migrate: F[Unit] =
    for {
      a <- createTables
      b <- copyAccounts
      c <- copyAlias
      d <- copyShare
      e <- copyFiles
      errs = a + b + c + d + e
      _ <-
        if (errs == 0)
          dropOldTables *> flywayBaseline *> logger.finfo[F]("Migration done")
        else logger.finfo[F]("Some error occured, you might try again")
    } yield ()

  def flywayBaseline: F[Unit] =
    Effect[F].delay {
      val fw = FlywayMigrate.baselineFlyway(cfg)
      fw.migrate()
      ()
    }

  def dropOldTables: F[Unit] =
    for {
      _ <- logger.finfo[F]("Dropping old tables")
      _ <- store.transact(sql"DROP TABLE dbversion".update.run)
      _ <- store.transact(sql"DROP TABLE uploadfile".update.run)
      _ <- store.transact(sql"DROP TABLE upload".update.run)
      _ <- store.transact(sql"DROP TABLE alias".update.run)
      _ <- store.transact(sql"DROP TABLE account".update.run)
    } yield ()

  def createTables: F[Int] = {
    val db = cfg.dbmsName match {
      case Some("h2") => "postgresql"
      case Some(n)    => n
      case None       => sys.error(s"Unknown dbms for url: ${cfg.url}")
    }
    val file = Option(
      getClass.getResource(s"/db/migration/$db/V1.0.0__initial.sql")
    ) match {
      case None    => sys.error("Schema file not found")
      case Some(f) => f
    }
    val text = fs2.io
      .readInputStream(Effect[F].delay(file.openStream()), 8 * 1024, blocker)
      .through(fs2.text.utf8Decode)
      .fold1(_ + _)
      .compile
      .lastOrError

    for {
      stmt <- text
      _    <- logger.finfo[F]("Creating new tables")
      n <-
        result(store.transact(Fragment.const(stmt).update.run), "Error creating tables")
    } yield n
  }

  def copyAlias: F[Int] = {
    val next: Fragment =
      sql"SELECT ROW_NUMBER() OVER() AS rn,t.* FROM alias t"

    logger.finfo[F]("Copying aliases...") *>
      loadChunks[OldAlias](next)(-1)
        .evalMap(_.toRAlias)
        .evalTap(a => logger.finfo[F](s"Inserting alias: $a"))
        .evalMap(a => result(store.transact(RAlias.insert(a)), "Error inserting alias"))
        .compile
        .foldMonoid
  }

  def copyShare: F[Int] = {
    val next: Fragment =
      sql"SELECT ROW_NUMBER() OVER() AS rn, t.* FROM upload t"

    logger.finfo[F]("Copying shares...") *>
      loadChunks[Upload](next)(-1)
        .evalMap(u =>
          for {
            share <- u.toShare
            psha  <- u.toPublish.value
            _     <- logger.finfo[F](s"Inserting share: $share")
            n     <- result(store.transact(RShare.insert(share)), "Error inserting share")
            _ <-
              psha.map(p => store.transact(RPublishShare.insert(p))).getOrElse(0.pure[F])
          } yield n
        )
        .compile
        .foldMonoid
  }

  def copyFiles: F[Int] = {
    val q: Fragment =
      sql"SELECT ROW_NUMBER() OVER() AS rn,t.* FROM uploadfile t"

    logger.finfo[F]("Copying files...") *>
      loadChunks[UploadFile](q)(-1)
        .evalMap(_.toRShareFile)
        .evalTap(f => logger.finfo[F](s"Insert file: $f"))
        .evalMap(f =>
          result(store.transact(RShareFile.insert(f)), "Error inserting file")
        )
        .compile
        .foldMonoid
  }

  def copyAccounts: F[Int] = {
    val next: Fragment =
      sql"SELECT ROW_NUMBER() OVER() AS rn,t.* FROM account t"

    logger.finfo[F]("Copying accounts...") *>
      loadChunks[OldAccount](next)(-1)
        .evalMap(_.toAccount)
        .evalTap(a => logger.finfo[F](s"Insert account: $a"))
        .evalMap(a =>
          result(store.transact(RAccount.insert(a)), "Error inserting account")
        )
        .compile
        .foldMonoid
  }

  def loadChunks[A <: RowNum: Read](q: Fragment)(start: Long): Stream[F, A] = {
    val query = fr"SELECT * FROM (" ++ q ++ fr") v WHERE v.rn > $start ORDER BY v.rn"

    Stream.eval(store.transact(query.query[A].stream.take(50).compile.toVector)).flatMap {
      v =>
        if (v.isEmpty) Stream.empty
        else Stream.emits(v) ++ loadChunks(q)(v.last.rownum)
    }
  }

  def result[A](fu: F[A], errmsg: => String): F[Int] =
    fu.attempt.flatMap {
      case Right(_) => 0.pure[F]
      case Left(ex) =>
        logger.ferror[F](ex)(errmsg).as(1)
    }

  def accountId(login: Ident): F[Ident] =
    store.transact(
      Sql
        .selectSimple(
          Seq(RAccount.Columns.id),
          RAccount.table,
          RAccount.Columns.login.is(login)
        )
        .query[Ident]
        .unique
    )

  def getFileLength(fid: Ident): F[ByteSize] =
    store.transact(
      sql"SELECT length FROM filemeta WHERE id = $fid".query[ByteSize].unique
    )

  trait RowNum {
    def rownum: Long
  }
  case class OldAccount(
      rownum: Long,
      login: Ident,
      password: Option[Password],
      email: Option[String],
      admin: Boolean,
      enabled: Boolean,
      extern: Boolean
  ) extends RowNum {
    def toAccount: F[RAccount] =
      for {
        now <- Timestamp.current[F]
        id  <- Ident.randomId[F]
      } yield RAccount(
        id,
        login,
        if (extern) AccountSource.Extern else AccountSource.Intern,
        if (enabled) AccountState.Active else AccountState.Disabled,
        password.getOrElse(Password.empty),
        email,
        admin,
        0,
        None,
        now
      )

  }

  case class UploadFile(
      rownum: Long,
      id: Ident,
      fileId: Ident,
      filename: Option[String],
      donwloads: Int,
      lastDownload: Option[Timestamp]
  ) extends RowNum {

    def toRShareFile: F[RShareFile] =
      for {
        now <- Timestamp.current[F]
        len <- getFileLength(fileId)
      } yield RShareFile(fileId, id, fileId, filename, now, len)
  }

  case class Upload(
      rownum: Long,
      id: Ident,
      login: Ident,
      alias: Option[Ident],
      descr: Option[String],
      validity: java.time.Duration,
      maxdl: Int,
      password: Option[Password],
      created: Timestamp,
      downloads: Int,
      lastdl: Option[Timestamp],
      publishId: Option[Ident],
      publishDate: Option[Timestamp],
      publishUntil: Option[Timestamp],
      name: Option[String]
  ) extends RowNum {

    def toShare: F[RShare] =
      for {
        accId <- accountId(login)
      } yield RShare(
        id,
        accId,
        alias,
        name,
        Duration(validity),
        maxdl,
        password,
        descr,
        created
      )

    def toPublish: OptionT[F, RPublishShare] =
      for {
        pid <- OptionT.fromOption[F](publishId)
        pd  <- OptionT.fromOption[F](publishDate)
        pu  <- OptionT.fromOption[F](publishUntil)
      } yield RPublishShare(pid, id, true, downloads, lastdl, pd, pu, pd)

  }

  case class OldAlias(
      rownum: Long,
      id: Ident,
      login: Ident,
      name: String,
      validity: java.time.Duration,
      created: Timestamp,
      enabled: Boolean
  ) extends RowNum {

    def toRAlias: F[RAlias] =
      for {
        accId <- accountId(login)
      } yield RAlias(id, accId, name, Duration(validity), enabled, created)
  }

  implicit def metaJavaDuration: Meta[java.time.Duration] =
    Meta[String].timap(s => java.time.Duration.parse(s))(_.toString)
}

object MigrateFrom06 {

  def apply[F[_]: Effect: ContextShift](
      cfg: JdbcConfig,
      connectEC: ExecutionContext,
      blocker: Blocker
  ): Resource[F, MigrateFrom06[F]] =
    for {
      store <- Store.create(cfg, connectEC, blocker, false)
    } yield new MigrateFrom06[F](cfg, store, blocker)

}
