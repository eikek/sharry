package sharry.store.doobie

import cats.effect.*
import cats.implicits.*

import sharry.store.*
import sharry.store.migrate.FlywayMigrate

import _root_.doobie.*
import _root_.doobie.implicits.*

final class StoreImpl[F[_]: Async](jdbc: JdbcConfig, fs: FileStore[F], xa: Transactor[F])
    extends Store[F] {

  def migrate: F[Int] =
    FlywayMigrate.run[F](jdbc).map(_.migrationsExecuted)

  def transact[A](prg: ConnectionIO[A]): F[A] =
    prg.transact(xa)

  def transact[A](prg: fs2.Stream[ConnectionIO, A]): fs2.Stream[F, A] =
    prg.transact(xa)

  def add(insert: ConnectionIO[Int], exists: ConnectionIO[Boolean]): F[AddResult] =
    for {
      save <- transact(insert).attempt
      exist <- save.swap.traverse(ex => transact(exists).map(b => (ex, b)))
    } yield exist.swap match {
      case Right(_)        => AddResult.Success
      case Left((_, true)) =>
        AddResult.EntityExists("Adding failed, because the entity already exists.")
      case Left((ex, _)) => AddResult.Failure(ex)
    }

  val fileStore: FileStore[F] = fs
}
