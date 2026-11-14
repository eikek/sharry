package sharry.backend.alias

import cats.data.OptionT
import cats.effect.*
import cats.implicits.*
import fs2.Stream

import sharry.backend.alias.OAlias.{AliasDetail, AliasInput}
import sharry.common.*
import sharry.store.AddResult
import sharry.store.Store
import sharry.store.records.RAlias
import sharry.store.records.RAliasMember

import doobie.*

trait OAlias[F[_]] {

  def create(alias: AliasInput): F[AddResult]

  def createF(alias: F[AliasInput]): F[AddResult]

  def modify(aliasId: Ident, accId: Ident, alias: AliasInput): F[AddResult]

  def findAll(accId: Ident, nameQuery: String): Stream[F, AliasDetail]

  def findById(id: Ident, accId: Ident): F[Option[AliasDetail]]

  def delete(id: Ident, accId: Ident): F[Boolean]
}

object OAlias {

  /** Details about an alias including a list of user-ids that make up its members. */
  case class AliasInput(alias: RAlias, members: List[Ident])

  case class AliasDetail(alias: RAlias, ownerLogin: Ident, members: List[AliasMember])

  case class AliasMember(accountId: Ident, login: Ident)

  def apply[F[_]: Async](store: Store[F]): Resource[F, OAlias[F]] =
    Resource.pure[F, OAlias[F]](new OAlias[F] {
      private val logger = sharry.logging.getLogger[F]

      def create(detail: AliasInput): F[AddResult] =
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

      def createF(alias: F[AliasInput]): F[AddResult] =
        alias.flatMap(create)

      def modify(
          aliasId: Ident,
          accId: Ident,
          detail: AliasInput
      ): F[AddResult] = {
        // Members must only be touched if the alias is owned by `accId`. The
        // members are removed before the update, because the alias id may change
        // and the foreign key has no `on update cascade`.
        val doUpdate = for {
          owned <- RAlias.existsByOwner(aliasId, accId)
          n <-
            if (owned)
              for {
                _ <- RAliasMember.deleteForAlias(aliasId)
                u <- RAlias.update(aliasId, accId, detail.alias)
                k <-
                  if (u > 0)
                    RAliasMember.insertForAlias(detail.alias.id, detail.members)
                  else 0.pure[ConnectionIO]
              } yield u + k
            else 0.pure[ConnectionIO]
        } yield n

        for {
          _ <- logger.debug(s"Modify alias '${aliasId.id}' to ${detail.alias}")
          n <- store.transact(doUpdate)
          res =
            if (n > 0) AddResult.Success
            else AddResult.Failure(new Exception("No rows modified!"))
        } yield res
      }

      def findAll(
          accId: Ident,
          nameQuery: String
      ): Stream[F, AliasDetail] =
        store
          .transact(RAlias.findAll(accId, nameQuery).evalMap(loadMembers))

      def findById(id: Ident, accId: Ident): F[Option[AliasDetail]] =
        store.transact(OptionT(RAlias.findById(id, accId)).semiflatMap(loadMembers).value)

      def delete(id: Ident, accId: Ident): F[Boolean] =
        store.transact(RAlias.delete(id, accId)).map(_ > 0)

      private def loadMembers(alias: (RAlias, Ident)): ConnectionIO[AliasDetail] =
        for {
          members <- RAliasMember.findForAlias(alias._1.id)
          conv = members.map(t => AliasMember(t._1.accountId, t._2))
        } yield AliasDetail(alias._1, alias._2, conv)

    })

}
