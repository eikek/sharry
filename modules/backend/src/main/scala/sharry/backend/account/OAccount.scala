package sharry.backend.account

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import sharry.backend.PasswordCrypt
import sharry.backend.share.{Queries => ShareQueries}
import sharry.common._
import sharry.common.syntax.all._
import sharry.store.AddResult
import sharry.store.Store
import sharry.store.doobie.DoobieMeta
import sharry.store.records._

import doobie._
import org.log4s._

trait OAccount[F[_]] {

  def create(acc: NewAccount): F[AddResult]

  def delete(id: Ident): OptionT[F, RAccount]

  def modify(id: Ident, acc: ModAccount): F[AddResult]

  def updateLoginStats(acc: AccountId): F[Unit]

  def createIfMissing(acc: NewAccount): F[RAccount]

  def findAccounts(loginQuery: String): Stream[F, AccountItem]

  def findById(id: Ident): F[Option[RAccount]]

  def findDetailById(id: Ident): F[Option[AccountItem]]

  def findByLogin(login: Ident): F[Option[RAccount]]

  def setEmail(id: Ident, email: Option[String]): F[AddResult]

  def changePassword(id: Ident, oldPw: Password, newPw: Password): F[AddResult]

  def findByAlias(alias: Ident): OptionT[F, RAccount]
}

object OAccount {
  private[this] val logger = getLogger

  def apply[F[_]: Async](store: Store[F]): Resource[F, OAccount[F]] =
    Resource.pure[F, OAccount[F]](new OAccount[F] {

      def changePassword(id: Ident, oldPw: Password, newPw: Password): F[AddResult] = {
        val update =
          store
            .transact(RAccount.updatePassword(id, PasswordCrypt.crypt(newPw)))
            .attempt
            .map(AddResult.fromUpdateExpectChange("Account not found."))

        val wrongPassword: AddResult =
          AddResult.Failure(new Exception("Password is wrong."))

        val notInternal: AddResult =
          AddResult.Failure(new Exception("Not an internal account."))

        val change = for {
          acc <- OptionT(findById(id))
          pwmatch = PasswordCrypt.check(oldPw, acc.password)
          intern  = acc.source == AccountSource.Intern
          res <-
            if (!intern) OptionT.some[F](notInternal)
            else if (!pwmatch) OptionT.some[F](wrongPassword)
            else OptionT.liftF(update)
        } yield res

        change.getOrElse(AddResult.Failure(new Exception("Account not found")))
      }

      def delete(id: Ident): OptionT[F, RAccount] =
        for {
          _      <- OptionT.liftF(logger.finfo(s"Delete account $id"))
          acc    <- OptionT(store.transact(RAccount.findById(id)))
          shares <- OptionT.liftF(store.transact(RShare.getAllByAccount(id)))
          _      <- OptionT.liftF(logger.finfo(s"Delete ${shares.size} shares of account $id"))
          _ <- OptionT.liftF(
            shares.traverse(shareId => ShareQueries.deleteShare(shareId, false)(store))
          )
          _ <- OptionT.liftF(store.transact(RAccount.delete(id)))
        } yield acc

      def setEmail(id: Ident, email: Option[String]): F[AddResult] =
        store.transact(RAccount.setEmail(id, email)).attempt.map(AddResult.fromEither)

      def findByLogin(login: Ident): F[Option[RAccount]] =
        store.transact(RAccount.findByLogin(login))

      def findById(id: Ident): F[Option[RAccount]] =
        store.transact(RAccount.findById(id))

      def findDetailById(id: Ident): F[Option[AccountItem]] =
        store.transact(Queries.findById(id))

      def findAccounts(loginQuery: String): Stream[F, AccountItem] =
        store.transact(Queries.findAll(loginQuery))

      def modify(id: Ident, acc: ModAccount): F[AddResult] =
        store
          .transact(RAccount.update(id, acc.copy(password = acc.password.map(cryptPw))))
          .attempt
          .map(AddResult.fromUpdateExpectChange("Account not found."))

      def create(acc: NewAccount): F[AddResult] = {
        val pw = PasswordCrypt.crypt(acc.password)

        val makeRecord: F[RAccount] =
          for {
            now <- Timestamp.current[F]
            u = RAccount(
              acc.id,
              CIIdent(acc.login),
              acc.source,
              acc.state,
              pw,
              acc.email,
              acc.admin,
              0,
              None,
              now
            )
          } yield u

        def insert(user: RAccount): ConnectionIO[Int] =
          RAccount.insert(user)(DoobieMeta.TraceLogging.handler)

        def accountExists: ConnectionIO[Boolean] =
          RAccount.existsByLogin(acc.login)

        acc.validate.fold(
          err => (AddResult.Failure(new Exception(err)): AddResult).pure[F],
          _ => {
            val msg = s"The account '${acc.login.id}' already exists."
            for {
              acc  <- makeRecord
              save <- store.add(insert(acc), accountExists)
            } yield save.fold(identity, _.withMsg(msg), identity)
          }
        )
      }

      def updateLoginStats(acc: AccountId): F[Unit] =
        store.transact(RAccount.updateStatsById(acc.id)).map(_ => ())

      def createIfMissing(acc: NewAccount): F[RAccount] =
        create(acc).flatMap {
          case AddResult.Success =>
            store
              .transact(RAccount.findByLogin(acc.login))
              .flatMap {
                case Some(a) => a.pure[F]
                case None =>
                  Async[F]
                    .raiseError(new Exception("Currently saved account not found!"))
              }
          case AddResult.EntityExists(msg) =>
            logger.fdebug[F](msg) *>
              store
                .transact(RAccount.findByLogin(acc.login))
                .flatMap {
                  case Some(a) => a.pure[F]
                  case None =>
                    Async[F]
                      .raiseError(new Exception("Currently saved account not found!"))
                }
          case AddResult.Failure(ex) =>
            Async[F].raiseError(ex)
        }

      def findByAlias(alias: Ident): OptionT[F, RAccount] =
        OptionT(store.transact(RAccount.findByAlias(alias)))
    })

  private def cryptPw(pw: Password): Password =
    PasswordCrypt.crypt(pw)
}
