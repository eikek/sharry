package sharry.store

import scala.concurrent.ExecutionContext

import cats.effect._
import fs2._

import sharry.store.doobie.StoreImpl

import _root_.doobie._
import _root_.doobie.hikari.HikariTransactor
import bitpeace.Bitpeace

trait Store[F[_]] {

  def transact[A](prg: ConnectionIO[A]): F[A]

  def transact[A](prg: Stream[ConnectionIO, A]): Stream[F, A]

  def bitpeace: Bitpeace[F]

  def add(insert: ConnectionIO[Int], exists: ConnectionIO[Boolean]): F[AddResult]
}

object Store {

  def create[F[_]: Async](
      jdbc: JdbcConfig,
      connectEC: ExecutionContext,
      runMigration: Boolean
  ): Resource[F, Store[F]] =
    for {
      xa <- HikariTransactor.newHikariTransactor[F](
        jdbc.driverClass,
        jdbc.url.asString,
        jdbc.user,
        jdbc.password,
        connectEC
      )
      st = new StoreImpl[F](jdbc, xa)
      _ <- if (runMigration) Resource.eval(st.migrate) else Resource.pure[F, Int](0)
    } yield st: Store[F]
}
