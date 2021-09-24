package sharry.backend.account

import fs2.Stream

import sharry.common._
import sharry.store.doobie.DoobieMeta._
import sharry.store.doobie._
import sharry.store.records._

import doobie._
import doobie.implicits._

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

  private def findAccountFragment(where1: Fragment): Query0[AccountItem] = {
    val aId = "a" :: RAccount.Columns.id
    val sAcc = "s" :: RShare.Columns.accountId
    val sId = "s" :: RShare.Columns.id

    val cols = RAccount.Columns.all
      .map("a" :: _)
      .map(_.f) :+ fr"COUNT(" ++ sId.f ++ fr") as shares"
    val from1 =
      RAccount.table ++ fr"a LEFT OUTER JOIN" ++ RShare.table ++ fr"s ON" ++ aId.is(sAcc)

    val group = fr"GROUP BY" ++ aId.f

    val (from, where) =
      if (where1 == Fragment.empty) (from1 ++ group, where1)
      else (from1, where1 ++ group)

    Sql
      .selectSimple(Sql.commas(cols), from, where)
      .query[AccountItem]
  }

}
