package sharry.backend.alias

import cats.effect._
import cats.implicits._
import org.log4s._
import fs2.Stream

import sharry.common._
import sharry.common.syntax.all._
import sharry.store.Store
import sharry.store.AddResult
import sharry.store.records.RAlias

trait OAlias[F[_]] {

  def create(alias: RAlias): F[AddResult]

  def createF(alias: F[RAlias]): F[AddResult]

  def modify(aliasId: Ident, accId: Ident, alias: RAlias): F[AddResult]

  def findAll(accId: Ident, nameQuery: String): Stream[F, RAlias]

  def findById(id: Ident, accId: Ident): F[Option[RAlias]]

  def delete(id: Ident, accId: Ident): F[Boolean]
}

object OAlias {
  private[this] val logger = getLogger

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OAlias[F]] =
    Resource.pure[F, OAlias[F]](new OAlias[F] {
      def create(alias: RAlias): F[AddResult] =
        store.add(RAlias.insert(alias), RAlias.existsById(alias.id))

      def createF(alias: F[RAlias]): F[AddResult] =
        alias.flatMap(create)

      def modify(aliasId: Ident, accId: Ident, alias: RAlias): F[AddResult] = {
        val exists = RAlias.existsById(alias.id)
        val modify = RAlias.update(aliasId, accId, alias)
        for {
          _   <- logger.fdebug(s"Modify alias '${aliasId.id}' to $alias")
          res <- store.add(modify, exists)
        } yield res
      }

      def findAll(accId: Ident, nameQuery: String): Stream[F, RAlias] =
        store.transact(RAlias.findAll(accId, nameQuery))

      def findById(id: Ident, accId: Ident): F[Option[RAlias]] =
        store.transact(RAlias.findById(id, accId))

      def delete(id: Ident, accId: Ident): F[Boolean] =
        store.transact(RAlias.delete(id, accId)).map(_ > 0)
    })

}
