package sharry.backend.alias

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import sharry.backend.alias.OAlias.{AliasDetail, AliasMember}
import sharry.common._
import sharry.common.syntax.all._
import sharry.store.AddResult
import sharry.store.Store
import sharry.store.records.RAlias
import sharry.store.records.RAliasMember

import doobie._
import org.log4s._

trait OAlias[F[_]] {

  def create(alias: AliasDetail[Ident]): F[AddResult]

  def createF(alias: F[AliasDetail[Ident]]): F[AddResult]

  def modify(aliasId: Ident, accId: Ident, alias: AliasDetail[Ident]): F[AddResult]

  def findAll(accId: Ident, nameQuery: String): Stream[F, AliasDetail[AliasMember]]

  def findById(id: Ident, accId: Ident): F[Option[AliasDetail[AliasMember]]]

  def delete(id: Ident, accId: Ident): F[Boolean]
}

object OAlias {
  private[this] val logger = getLogger

  /** Details about an alias including a list of user-ids that make up its members. */
  case class AliasDetail[A](alias: RAlias, members: List[A])

  case class AliasMember(accountId: Ident, login: Ident)

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OAlias[F]] =
    Resource.pure[F, OAlias[F]](new OAlias[F] {
      def create(detail: AliasDetail[Ident]): F[AddResult] =
        store.add(
          for {
            n <- RAlias.insert(detail.alias)
            k <-
              if (n > 0)
                RAliasMember.insertForAlias(detail.alias.id, detail.members)
              else 0.pure[ConnectionIO]
          } yield n + k,
          RAlias.existsById(detail.alias.id)
        )

      def createF(alias: F[AliasDetail[Ident]]): F[AddResult] =
        alias.flatMap(create)

      def modify(
          aliasId: Ident,
          accId: Ident,
          detail: AliasDetail[Ident]
      ): F[AddResult] = {
        val doUpdate = for {
          n <- RAlias.update(aliasId, accId, detail.alias)
          k <-
            if (n > 0) RAliasMember.updateForAlias(aliasId, detail.members)
            else 0.pure[ConnectionIO]
        } yield n + k

        for {
          _ <- logger.fdebug(s"Modify alias '${aliasId.id}' to ${detail.alias}")
          n <- store.transact(doUpdate)
          res =
            if (n > 0) AddResult.Success
            else AddResult.Failure(new Exception("No rows modified!"))
        } yield res
      }

      def findAll(
          accId: Ident,
          nameQuery: String
      ): Stream[F, AliasDetail[AliasMember]] =
        store
          .transact(RAlias.findAll(accId, nameQuery).evalMap(loadMembers))

      def findById(id: Ident, accId: Ident): F[Option[AliasDetail[AliasMember]]] =
        store.transact(OptionT(RAlias.findById(id, accId)).semiflatMap(loadMembers).value)

      def delete(id: Ident, accId: Ident): F[Boolean] =
        store.transact(RAlias.delete(id, accId)).map(_ > 0)

      private def loadMembers(alias: RAlias): ConnectionIO[AliasDetail[AliasMember]] =
        for {
          members <- RAliasMember.findForAlias(alias.id)
          conv = members.map(t => AliasMember(t._1.accountId, t._2))
        } yield AliasDetail(alias, conv)

    })

}
