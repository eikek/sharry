package sharry.store.binary

import java.time.Instant
import java.time.temporal._
import org.log4s._
import fs2.{Pipe, Stream, Task}
import fs2.util.Catchable
import cats.free.Free.pure
import scodec.bits.ByteVector
import doobie.imports._

import sharry.store.data._
import sharry.common._
import sharry.common.mime._
import sharry.common.sizes._
import sharry.common.streams
import sharry.store.range._
import sharry.store.mimedetect._

class SqlBinaryStore(xa: Transactor[Task]) extends BinaryStore with Statements {
  implicit private[this] val logger = getLogger

  def delete(id: String): Stream[Task,Boolean] = {
    val sql = for {
      n <- deleteChunks(id).run
      _ <- deleteFileMeta(id).run
    } yield n > 0
    streams.slog[Task](_.trace(s"Deleting file $id")) ++ Stream.eval(sql.transact(xa))
  }


  def count: Stream[Task,Int] =
    Stream.eval(sql"""SELECT count(*) from FileMeta""".query[Int].unique.transact(xa))

  def saveTemp(data: Stream[Task,Byte], chunkSize: Size, mimeInfo: MimeInfo, time: Instant): Stream[Task,(String, FileMeta)] = {
    val id = FileMeta.randomId
    data.through(rechunk(chunkSize)).zipWithIndex.
      map(t => FileChunk(id, t._2, t._1)).
      flatMap(ch =>
        streams.slog[Task](_.trace(s"Insert chunk ${ch.chunkNr} (len=${ch.chunkLength})")) ++
          Stream.eval(insertChunk(ch).run.transact(xa).map(_ => ch))
      ).
      through(accumulateKey(time, chunkSize, mimeInfo)).
      map(key => (id, key))
  }

  def makeFinal(k: (String, FileMeta)): Stream[Task,Outcome[FileMeta]] =
    get(k._2.id).flatMap {
      case Some(fm) =>
        delete(k._1).map(_ => Unmodified(fm))
      case None =>
        val update: ConnectionIO[Outcome[FileMeta]] = for {
          idUpdate <- updateChunkId(k._1, k._2.id).run.attemptSql
          meta     <- idUpdate match {
            case Right(_) => insertFileMeta(k._2).run.map(_ => Created(k._2))
            case Left(sqlex) =>
              //fix unique constraint error, fail on everything else
              for {
                _ <- deleteChunks(k._1).run
                m <- selectFileMeta(k._2.id).flatMap {
                  case Some(meta) =>
                    pure(Unmodified(meta)): ConnectionIO[Outcome[FileMeta]]
                  case None =>
                    val err: ConnectionIO[Outcome[FileMeta]] = Catchable[ConnectionIO].fail {
                      new Exception(s"Cannot update file key $k but cannot find it", sqlex)
                    }
                    err
                }
              } yield m
          }
        } yield meta.map(m => m.copy(timestamp = m.timestamp.truncatedTo(ChronoUnit.SECONDS)))
        Stream.eval(update.transact(xa))
    }

  def get(id: String): Stream[Task,Option[FileMeta]] = {
    Stream.eval(selectFileMeta(id).transact(xa))
  }

  def fetchData(range: RangeSpec): Pipe[Task, FileMeta, Byte] = {
    def mkData(id: String, chunksLeft: Int, chunk: Int): Stream[Task,ByteVector] =
      if (chunksLeft == 0) Stream.empty
      else Stream.eval(selectChunkData(id, Some(chunk).filter(_ > 0), Some(1)).unique.transact(xa)) ++ mkData(id, chunksLeft -1, chunk+1)

    _.flatMap { fm =>
      range(FileSettings(fm.length, fm.chunksize)) match {
        case Some(r) =>
          logger.trace(s"Get file ${fm.id} for $r")
          mkData(fm.id, r.limit.getOrElse(fm.chunks - r.offset.getOrElse(0)), r.offset.getOrElse(0)).
            through(Range.dropLeft(r)).
            through(Range.dropRight(r)).
            through(streams.unchunk)
        case None =>
          logger.trace(s"Get file ${fm.id} (no range)")
          mkData(fm.id, fm.chunks, 0).through(streams.unchunk)
      }
    }
  }

  def fetchData2(range: RangeSpec): Pipe[Task, FileMeta, Byte] =
    _.flatMap { fm =>
      range(FileSettings(fm.length, fm.chunksize)).map { r =>
        logger.trace(s"Get file ${fm.id} for $r")
        r.select(selectChunkData(fm.id, r.offset, r.limit).process.transact(xa))
      } getOrElse {
        logger.trace(s"Get file ${fm.id} (no range)")
        selectChunkData(fm.id).process.transact(xa).
          through(streams.unchunk)
      }
    }


  def exists(id: String): Stream[Task,Boolean] =
    Stream.eval(fileExists(id).transact(xa).map(_.isDefined))

  def getChunks(checksum: String, offset: Option[Int] = None, limit: Option[Int] = None): Stream[Task,FileChunk] =
    selectChunks(checksum, offset, limit).process.transact(xa)

  def saveFileMeta(fm: FileMeta): Stream[Task, Unit] =
    Stream.eval(insertFileMeta(fm).run.transact(xa)).map(_ => ())

  def saveFileChunk(ch: FileChunk): Stream[Task, Unit] =
    Stream.eval(insertChunk(ch).run.transact(xa)).map(_ => ())

  private def rechunk[F[_]](size: Size): Pipe[F, Byte, ByteVector] =
    _.rechunkN(size.bytes, true).through(streams.toByteChunks)

  private def accumulateKey[F[_]](time: Instant, chunkSize: Size, mimeInfo: MimeInfo): Pipe[Task, FileChunk, FileMeta] =
    _.fold((sha.newBuilder, FileMeta("", time, MimeType.unknown, Size.zero, 0, chunkSize)))({
      case ((shab, m), chunk) if m.chunks == 0 =>
        (shab.update(chunk.chunkData), m.incChunks(1).incLength(chunk.chunkLength).setMimeType(fromBytes(chunk.chunkData, mimeInfo)))
      case ((shab, m), chunk) =>
        (shab.update(chunk.chunkData), m.incChunks(1).incLength(chunk.chunkLength))
    }).map(t => t._2.copy(id = t._1.get))
}
