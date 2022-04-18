package sharry.restserver.routes

import cats.effect._
import cats.implicits._

import sharry.backend.BackendApp
import sharry.backend.account.AccountItem
import sharry.backend.auth.AuthToken
import sharry.restapi.model._

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object AliasMemberRoutes {
  def apply[F[_]: Async](
      backend: BackendApp[F],
      token: AuthToken
  ): HttpRoutes[F] = {
    val logger = sharry.logging.getLogger[F]
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case req @ GET -> Root =>
      val q = req.params.getOrElse("q", "")
      for {
        _ <- logger.trace(s"Listing accounts for ${token.account}")
        list <- backend.account
          .findAccounts(q)
          .filter(a => a.acc.id != token.account.id)
          .take(100)
          .compile
          .toVector
        resp <- Ok(AccountLightList(list.map(convert).toList))
      } yield resp
    }
  }

  private def convert(r: AccountItem): AccountLight =
    AccountLight(r.acc.id, r.acc.login.value)

}
