package sharry.backend.signup

import cats.effect._
import cats.implicits._

import sharry.backend.account._
import sharry.common._
import sharry.common.syntax.all._
import sharry.store.records.RInvitation
import sharry.store.{AddResult, Store}

import org.log4s.getLogger

trait OSignup[F[_]] {

  def register(cfg: SignupConfig)(data: OSignup.RegisterData): F[SignupResult]

  def newInvite(cfg: SignupConfig)(password: Password): F[NewInviteResult]

  /** Removes unused and expired invites.
    */
  def cleanInvites(cfg: SignupConfig): F[Int]
}

object OSignup {
  private[this] val logger = getLogger

  case class RegisterData(login: Ident, password: Password, invite: Option[Ident])

  def apply[F[_]: ConcurrentEffect](store: Store[F]): Resource[F, OSignup[F]] =
    Resource.pure[F, OSignup[F]](new OSignup[F] {

      def newInvite(cfg: SignupConfig)(password: Password): F[NewInviteResult] =
        if (cfg.mode != SignupMode.Invite)
          Effect[F].pure(NewInviteResult.invitationClosed)
        else if (cfg.invitePassword != password)
          Effect[F].pure(NewInviteResult.passwordMismatch)
        else
          store.transact(RInvitation.insertNew).map(ri => NewInviteResult.success(ri.id))

      def cleanInvites(cfg: SignupConfig): F[Int] =
        for {
          now <- Timestamp.current[F]
          date = now.minus(cfg.inviteTime)
          n <- store.transact(RInvitation.deleteOlderThan(date))
        } yield n

      def register(cfg: SignupConfig)(data: RegisterData): F[SignupResult] =
        cfg.mode match {
          case SignupMode.Open =>
            addUser(data).map(SignupResult.fromAddResult)

          case SignupMode.Closed =>
            SignupResult.signupClosed.pure[F]

          case SignupMode.Invite =>
            data.invite match {
              case Some(inv) =>
                for {
                  now <- Timestamp.current[F]
                  min = now.minus(cfg.inviteTime)
                  ok <- store.transact(RInvitation.useInvite(inv, min))
                  res <-
                    if (ok) addUser(data).map(SignupResult.fromAddResult)
                    else SignupResult.invalidInvitationKey.pure[F]
                  _ <-
                    if (retryInvite(res))
                      logger.fdebug(
                        s"Adding account failed ($res). Allow retry with invite."
                      ) *> store
                        .transact(
                          RInvitation.insert(RInvitation(inv, now))
                        )
                    else 0.pure[F]
                } yield res
              case None =>
                SignupResult.invalidInvitationKey.pure[F]
            }
        }

      private def retryInvite(res: SignupResult): Boolean =
        res match {
          case SignupResult.AccountExists =>
            true
          case SignupResult.InvalidInvitationKey =>
            false
          case SignupResult.SignupClosed =>
            true
          case SignupResult.Failure(_) =>
            true
          case SignupResult.Success =>
            false
        }

      private def addUser(data: RegisterData): F[AddResult] =
        for {
          acc <- NewAccount.create[F](
            data.login,
            AccountSource.Intern,
            AccountState.Active,
            data.password,
            None,
            false
          )
          res <- OAccount(store).use(_.create(acc))
        } yield res
    })
}
