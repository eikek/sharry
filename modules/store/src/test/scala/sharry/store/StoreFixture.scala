package sharry.store

import java.nio.file.Paths

import scala.util.Random

import cats.effect.*
import cats.effect.unsafe.implicits.global
import fs2.io.file.Files

import sharry.common.*
import sharry.store.doobie.*

import _root_.doobie.*
import org.h2.jdbcx.JdbcConnectionPool
import scodec.bits.ByteVector

trait StoreFixture {

  def withStore(code: Store[IO] => IO[Unit]): Unit =
    StoreFixture.makeStore[IO].use(code).unsafeRunSync()
}

object StoreFixture {
  private val logger = sharry.logging.unsafeLogger("StoreFixture")

  def makeStore[F[_]: Async: Files]: Resource[F, Store[F]] = {
    def dataSource(jdbc: JdbcConfig): Resource[F, JdbcConnectionPool] = {
      def jdbcConnPool =
        JdbcConnectionPool.create(jdbc.url.asString, jdbc.user, jdbc.password)

      Resource.make(Sync[F].delay(jdbcConnPool))(cp => Sync[F].delay(cp.dispose()))
    }

    val dbname = Sync[F].delay {
      val bytes = new Array[Byte](16)
      Random.nextBytes(bytes)
      val name = ByteVector.view(bytes).toBase64NoPad
      val db = Paths.get("./target", name).normalize.toAbsolutePath
      logger.debug(s"Using db: $db")
      db.toString
    }

    for {
      db <- Resource.eval(dbname)
      jdbc = JdbcConfig(
        LenientUri.unsafe(s"jdbc:h2:$db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE"),
        "sa",
        ""
      )
      ds <- dataSource(jdbc)
      connectEC <- ExecutionContexts.cachedThreadPool[F]
      tx = Transactor.fromDataSource[F](ds, connectEC)
      fs <- Resource.eval(
        FileStore[F](
          ds,
          tx,
          64 * 1024,
          ComputeChecksumConfig.default,
          FileStoreConfig.DefaultDatabase(enabled = true)
        )
      )
      st = new StoreImpl[F](jdbc, fs, tx)
      _ <- Resource.eval(st.migrate)
    } yield st
  }
}
