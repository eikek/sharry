package sharry.store

import scala.concurrent.ExecutionContext
import cats.effect._
import fs2._
import sharry.store.doobie.StoreImpl
import _root_.doobie._
import _root_.doobie.hikari.HikariTransactor
import com.zaxxer.hikari.HikariDataSource
import sharry.common.ByteSize

trait Store[F[_]] {

  def transact[A](prg: ConnectionIO[A]): F[A]

  def transact[A](prg: Stream[ConnectionIO, A]): Stream[F, A]

  def fileStore: FileStore[F]

  def add(insert: ConnectionIO[Int], exists: ConnectionIO[Boolean]): F[AddResult]
}

object Store {

  def create[F[_]: Async](
      jdbc: JdbcConfig,
      chunkSize: ByteSize,
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
      xa <- Resource.pure(HikariTransactor[F](ds, connectEC))
      fs = FileStore[F](ds, xa, chunkSize.bytes.toInt)
      st = new StoreImpl[F](jdbc, fs, xa)
      _ <- if (runMigration) Resource.eval(st.migrate) else Resource.pure[F, Int](0)
    } yield st: Store[F]
}
