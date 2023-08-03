package sharry.backend

import scala.concurrent.ExecutionContext

import cats.effect._
import fs2.io.file.Files

import sharry.backend.account._
import sharry.backend.alias.OAlias
import sharry.backend.auth.Login
import sharry.backend.config.Config
import sharry.backend.files.OFiles
import sharry.backend.job.PeriodicCleanup
import sharry.backend.mail.OMail
import sharry.backend.share.OShare
import sharry.backend.signup.OSignup
import sharry.store.Store

import emil.javamail.JavaMailEmil

trait BackendApp[F[_]] {

  def login: Login[F]

  def signup: OSignup[F]

  def account: OAccount[F]

  def alias: OAlias[F]

  def share: OShare[F]

  def mail: OMail[F]

  def files: OFiles[F]
}

object BackendApp {

  def create[F[_]: Async](cfg: Config, store: Store[F]): Resource[F, BackendApp[F]] =
    for {
      accountImpl <- OAccount[F](store)
      loginImpl <- Login[F](accountImpl)
      signupImpl <- OSignup[F](store)
      aliasImpl <- OAlias[F](store)
      shareImpl <- OShare[F](store, cfg.share)
      mailImpl <- OMail[F](store, cfg.mail, JavaMailEmil[F]())
      filesImpl <- Resource.pure(OFiles[F](store, cfg.files))
    } yield new BackendApp[F] {
      val login: Login[F] = loginImpl
      val signup: OSignup[F] = signupImpl
      val account: OAccount[F] = accountImpl
      val alias: OAlias[F] = aliasImpl
      val share: OShare[F] = shareImpl
      val mail: OMail[F] = mailImpl
      val files: OFiles[F] = filesImpl
    }

  def apply[F[_]: Async: Files](
      cfg: Config,
      connectEC: ExecutionContext
  ): Resource[F, BackendApp[F]] =
    for {
      store <- Store.create(
        cfg.jdbc,
        cfg.share.chunkSize,
        cfg.computeChecksum,
        cfg.files.defaultStoreConfig,
        connectEC,
        true
      )

      backend <- create(cfg, store)
      _ <-
        PeriodicCleanup.resource(cfg.cleanup, cfg.signup, backend.share, backend.signup)
    } yield backend
}
