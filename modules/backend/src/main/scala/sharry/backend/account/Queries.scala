package sharry.backend.account

import fs2.Stream
import doobie._, doobie.implicits._

import sharry.common._
import sharry.store.doobie._
import sharry.store.doobie.DoobieMeta._
import sharry.store.records._

object Queries {

  def findAll(loginQ: String): Stream[ConnectionIO, AccountItem] = {
    val aLogin = "a" :: RAccount.Columns.login

    val q =
      if (loginQ.isEmpty) Fragment.empty
      else aLogin.like("%" + loginQ + "%")

    findAccountFragment(q).stream
  }

  def findById(id: Ident): ConnectionIO[Option[AccountItem]] = {
    val aId = "a" :: RAccount.Columns.id
    findAccountFragment(aId.is(id)).option
  }

  def findByLogin(login: Ident): ConnectionIO[Option[AccountItem]] = {
    val aLogin = "a" :: RAccount.Columns.login
    findAccountFragment(aLogin.is(login)).option
  }

  private def findAccountFragment(where: Fragment): Query0[AccountItem] = {
    val aId  = "a" :: RAccount.Columns.id
    val sAcc = "s" :: RShare.Columns.accountId
    val sId  = "s" :: RShare.Columns.id

    val cols = RAccount.Columns.all.map("a" :: _).map(_.f) :+ fr"COUNT(" ++ sId.f ++ fr") as shares"
    val from = RAccount.table ++ fr"a LEFT OUTER JOIN" ++ RShare.table ++ fr"s ON" ++ aId.is(sAcc) ++ fr"GROUP BY" ++ aId.f

    Sql.selectSimple(Sql.commas(cols), from, where).query[AccountItem]
  }

}
