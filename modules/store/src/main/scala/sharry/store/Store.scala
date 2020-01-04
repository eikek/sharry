package sharry.store

import bitpeace.Bitpeace
import cats.effect._
import fs2._
import _root_.doobie._
import _root_.doobie.hikari.HikariTransactor
import sharry.store.doobie.StoreImpl

import scala.concurrent.ExecutionContext

trait Store[F[_]] {

  def transact[A](prg: ConnectionIO[A]): F[A]

  def transact[A](prg: Stream[ConnectionIO, A]): Stream[F, A]

  def bitpeace: Bitpeace[F]

  def add(insert: ConnectionIO[Int], exists: ConnectionIO[Boolean]): F[AddResult]
}

object Store {

  def create[F[_]: Effect: ContextShift](
      jdbc: JdbcConfig,
      connectEC: ExecutionContext,
      blocker: Blocker,
      runMigration: Boolean
  ): Resource[F, Store[F]] = {

    val hxa = HikariTransactor.newHikariTransactor[F](
      jdbc.driverClass,
      jdbc.url.asString,
      jdbc.user,
      jdbc.password,
      connectEC,
      blocker
    )

    for {
      xa <- hxa
      st = new StoreImpl[F](jdbc, xa)
      _  <- if (runMigration) Resource.liftF(st.migrate) else Resource.pure(())
    } yield st
  }
}
