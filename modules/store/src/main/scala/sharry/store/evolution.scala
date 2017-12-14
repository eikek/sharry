package sharry.store

import org.log4s._
import fs2.{Pure, Stream, Task}
import doobie.imports._
import fs2.interop.cats._
import sharry.common.streams

object evolution {

  implicit private[this] val logger = getLogger

  type Change = Transactor[Task] => Stream[Task, Unit]

  object Change {
    def apply(update: Update0): Change =
      xa => {
        streams.slogT(_.info(update.sql)) ++
        Stream.eval(update.run.transact(xa)).map(_ => ())
      }
  }

  sealed trait Dbms {
    def blob: Fragment
    def currentTimestamp: Fragment
    def dropDatabase(db: String): Fragment
  }
  case object H2 extends Dbms {
    val blob = Fragment.const("blob")
    val currentTimestamp = Fragment.const("current_timestamp()")

    def dropDatabase(db: String) = fr"drop all objects delete files;"

  }
  case object Postgres extends Dbms {
    val blob = Fragment.const("bytea")
    val currentTimestamp = Fragment.const("current_timestamp")

    def dropDatabase(db: String) = fr"drop database $db; create database $db;"
  }

  object Dbms {
    def apply(jdbcUrl: String): Dbms =
      jdbcUrl.split(":").toList match {
        case _ :: "postgresql" :: _ => Postgres
        case _ :: "h2" :: _ => H2
        case _ => sys.error(s"unknown dbms: $jdbcUrl")
      }
  }

  def apply(jdbcUrl: String): Runner =
    new Runner(Dbms(jdbcUrl), "sitebagdev")

  def apply(dbms: Dbms, db: String): Runner =
    new Runner(dbms, db)

  final class Runner(dbms: Dbms, db: String) {

    private val changes = changesFor(dbms)

    /** Run all changes not yet applied */
    def runChanges(xa: Transactor[Task]): Task[Unit] = {
      Stream.eval(getState(xa)).flatMap { version =>
        changes.zipWithIndex.drop(version.toLong).flatMap {
          case (change, idx) =>
            change(xa) ++ Stream.eval(updateState(idx+1)(xa))
        }
      }.run
    }

    /** get the current state of the database */
    def getState(xa: Transactor[Task]): Task[Int] = {
      val version = sql"""SELECT max(version) FROM dbversion"""
        .query[Int]
        .unique
        .transact(xa)
      version or Task.now(0)
    }

    def dropDatabase(xa: Transactor[Task]): Task[Unit] = {
      dbms.dropDatabase(db).update.run.transact(xa).map(_ => ())
    }

    private def updateState(version: Int)(xa: Transactor[Task]): Task[Unit] = {
      sql"""INSERT INTO dbversion (version) VALUES ($version)""".update
        .run.transact(xa).map(_ => ())
    }
  }

  def changesFor(dbms: Dbms): Stream[Pure, Change] = Stream(
    /* This table is used to track this list of changes. When the changes
     * are applied to a database, it can use this info to run only the
     * changes that have not been applied.
     */
    Change((fr"""CREATE TABLE IF NOT EXISTS dbversion (
        createdb timestamp not null default""" ++ dbms.currentTimestamp ++ fr""",
        version int not null,
        primary key (version)
      );
      """).update),

    /* BinaryStore. Following tables are for storing binary data. In order
     * to have some random access to the bytes, they are not stored as
     * one blob, but in chunks of blobs. Additionally, the
     * content-type is stored.
     */
    Change((fr"""
      CREATE TABLE IF NOT EXISTS FileMeta (
        id varchar(64) not null,
        timestamp varchar(40) not null,
        mimetype varchar(254) not null,
        length bigint not null,
        chunks int not null,
        chunksize int not null,
        primary key (id)
      );
      CREATE TABLE IF NOT EXISTS FileChunk (
        fileId varchar(64) not null,
        chunkNr int not null,
        chunkLength int not null,
        chunkData""" ++ dbms.blob ++ fr""" not null,
        primary key (fileId, chunkNr)
      );""").update),

    /* This table is used to maintain accounts to the application.
     */
    Change(sql"""
      CREATE TABLE IF NOT EXISTS Account (
        login varchar(254) not null,
        password varchar(254) null,
        email varchar(254) null,
        admin boolean not null,
        enabled boolean not null,
        extern boolean not null,
        primary key (login));
      CREATE INDEX account_email_idx ON Account(email);""".update),

    Change(sql"""
      CREATE TABLE IF NOT EXISTS Upload (
        id varchar(254) not null primary key,
        login varchar(254) not null,
        alias varchar(254),
        description text,
        validity varchar(50) not null,
        maxdownloads int,
        password varchar(254),
        created varchar(40) not null,
        downloads int,
        lastDownload varchar(40),
        publishId varchar(200),
        publishDate varchar(40),
        publishUntil varchar(40),
        foreign key (login) references Account(login) on delete cascade);
      CREATE INDEX uploadconfig_publishid_idx ON Upload(publishId);
      CREATE INDEX uploadconfig_publishuntil_idx ON Upload(publishUntil);
      CREATE INDEX uploadconfig_publishdate_idx ON Upload(publishDate);""".update),

    Change(sql"""
      CREATE TABLE IF NOT EXISTS UploadFile (
        uploadId varchar(254) not null,
        fileId varchar(64) not null,
        filename varchar(2000),
        downloads int,
        lastDownload varchar(40),
        primary key (uploadId, fileId),
        foreign key (uploadId) references Upload(id),
        foreign key (fileId) references FileMeta(id))""".update),

    Change(sql"""
      CREATE TABLE IF NOT EXISTS Alias (
         id varchar(254) not null primary key,
         login varchar(254) not null,
         name varchar(254) not null,
         validity varchar(50) not null,
         created varchar(40) not null,
         enable boolean not null
      )""".update),

    Change(sql"""
       ALTER TABLE UploadFile ADD COLUMN clientFileId varchar(512);
       UPDATE UploadFile SET clientFileId = fileId WHERE clientFileId is null;
       """.update),

    Change(sql"""
       ALTER TABLE FileMeta ADD COLUMN checksum varchar(254);
       UPDATE FileMeta SET checksum = id WHERE checksum is null;
       ALTER TABLE FileMeta ALTER COLUMN checksum set not null;
      """.update),
    Change(sql"""UPDATE FileChunk SET chunkNr = chunkNr - 1""".update)
  ).pure
}
