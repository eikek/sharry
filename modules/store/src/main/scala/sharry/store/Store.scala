package sharry.store

import scala.concurrent.ExecutionContext

import cats.effect._
import fs2._
import fs2.io.file.Files

import sharry.common.ByteSize
import sharry.store.doobie.StoreImpl

import _root_.doobie._
import _root_.doobie.util.log.{LogEvent, Success}
import _root_.doobie.hikari.HikariTransactor
import com.zaxxer.hikari.HikariDataSource

trait Store[F[_]] {

  def transact[A](prg: ConnectionIO[A]): F[A]

  def transact[A](prg: Stream[ConnectionIO, A]): Stream[F, A]

  def fileStore: FileStore[F]

  def add(insert: ConnectionIO[Int], exists: ConnectionIO[Boolean]): F[AddResult]
}

object Store {

  private object DefaultLogging {
    implicit def handler[F[_]: Sync]: LogHandler[F] =
      new LogHandler[F] {
        val logger = sharry.logging.getLogger[F]("DoobieMeta")
        def run(e: LogEvent) = e match {
          case e @ Success(_, _, _, _, _) =>
            logger.trace("SQL success: " + e)
          case e =>
            if (e.label == "trace") logger.trace(s"SQL failure: $e")
            else logger.warn(s"SQL failure: $e")
        }
      }
  }

  def create[F[_]: Async: Files](
      jdbc: JdbcConfig,
      chunkSize: ByteSize,
      computeChecksumConfig: ComputeChecksumConfig,
      fileStoreCfg: FileStoreConfig,
      connectEC: ExecutionContext,
      runMigration: Boolean
  ): Resource[F, Store[F]] =
    for {
      ds <- Resource.make(Async[F].delay(new HikariDataSource()))(s =>
        Async[F].delay(s.close())
      )
      _ <- Resource.pure {
        ds.setJdbcUrl(jdbc.url.asString)
        ds.setUsername(jdbc.user)
        ds.setPassword(jdbc.password)
        ds.setDriverClassName(jdbc.driverClass)
      }
      xa <- Resource.pure(HikariTransactor[F](ds, connectEC, Some(DefaultLogging.handler[F])))
      fs <- Resource.eval(
        FileStore[F](ds, xa, chunkSize.bytes.toInt, computeChecksumConfig, fileStoreCfg)
      )
      st = new StoreImpl[F](jdbc, fs, xa)
      _ <- if (runMigration) Resource.eval(st.migrate) else Resource.pure[F, Int](0)
    } yield st: Store[F]
}
