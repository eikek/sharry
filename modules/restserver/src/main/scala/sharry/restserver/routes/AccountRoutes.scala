package sharry.restserver.routes

import cats.effect._
import cats.implicits._
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.dsl.Http4sDsl
import org.log4s._

import sharry.backend.BackendApp
import sharry.restapi.model._
import sharry.restserver.Config
import sharry.common._
import sharry.common.syntax.all._
import sharry.store.records.ModAccount
import cats.data.OptionT
import sharry.backend.account.{AccountItem, NewAccount}

object AccountRoutes {
  private[this] val logger = getLogger

  def apply[F[_]: Effect](backend: BackendApp[F], cfg: Config): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    val r1 = HttpRoutes[F]({ case GET -> Root / Ident(id) =>
      for {
        _    <- OptionT.liftF(logger.fdebug(s"Loading accout $id"))
        acc  <- OptionT(backend.account.findDetailById(id))
        resp <- OptionT.liftF(Ok(accountDetail(acc)))
      } yield resp
    })
    val r2 = HttpRoutes.of[F] {
      case req @ POST -> Root / Ident(id) =>
        for {
          in <- req.as[AccountModify]
          res <- backend.account.modify(
            id,
            ModAccount(in.state, in.admin, in.email, in.password)
          )
          resp <- Ok(Conv.basicResult(res, "Account successfully modified."))
        } yield resp

      case req @ GET -> Root =>
        val q = req.params.getOrElse("q", "")
        for {
          _   <- logger.ftrace(s"Listing accounts: $q")
          all <- backend.account.findAccounts(q).take(100).compile.toVector
          list = AccountList(all.map(accountDetail).toList)
          resp <- Ok(list)
        } yield resp

      case req @ POST -> Root =>
        for {
          in <- req.as[AccountCreate]
          acc <- NewAccount.create(
            in.login,
            AccountSource.Intern,
            in.state,
            in.password,
            in.email,
            in.admin
          )
          res  <- backend.account.create(acc)
          resp <- Ok(Conv.basicResult(res, "Account successfully created."))
        } yield resp
    }
    r2 <+> r1
  }

  def accountDetail(a: AccountItem): AccountDetail =
    AccountDetail(
      a.acc.id,
      a.acc.login,
      a.acc.source,
      a.acc.state,
      a.acc.admin,
      a.acc.email,
      a.acc.loginCount,
      a.shares,
      a.acc.lastLogin,
      a.acc.created
    )

}
