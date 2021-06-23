package sharry.store

import java.nio.file.Paths

import scala.util.Random

import cats.effect._
import cats.effect.unsafe.implicits.global

import sharry.common._
import sharry.store.doobie._

import _root_.doobie.util.transactor.Transactor
import org.log4s.getLogger
import scodec.bits.ByteVector

trait StoreFixture {

  def withStore(code: Store[IO] => IO[Unit]): Unit =
    StoreFixture.makeStore[IO].use(code).unsafeRunSync()
}

object StoreFixture {
  private[this] val logger = getLogger

  def makeStore[F[_]: Async]: Resource[F, Store[F]] = {
    def transactor(jdbc: JdbcConfig): Transactor[F] =
      Transactor.fromDriverManager[F](
        jdbc.driverClass,
        jdbc.url.asString,
        jdbc.user,
        jdbc.password
      )

    val dbname = Sync[F].delay {
      val bytes = new Array[Byte](16)
      Random.nextBytes(bytes)
      val name = ByteVector.view(bytes).toBase64NoPad
      val db   = Paths.get("./target", name).normalize.toAbsolutePath
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
      tx = transactor(jdbc)
      st = new StoreImpl[F](jdbc, tx)
      _ <- Resource.eval(st.migrate)
    } yield st
  }
}
