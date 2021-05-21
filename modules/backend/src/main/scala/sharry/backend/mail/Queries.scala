package sharry.backend.mail

import cats.data.OptionT

import sharry.common._
import sharry.store.doobie.DoobieMeta._
import sharry.store.doobie._
import sharry.store.records._

import doobie._
import doobie.implicits._
import emil.MailAddress

object Queries {

  def findNotifyData(aliasId: Ident, shareId: Ident): ConnectionIO[Option[NotifyData]] = {
    val aId      = "a" :: RAlias.Columns.id
    val aAccount = "a" :: RAlias.Columns.account
    val aName    = "a" :: RAlias.Columns.name
    val uId      = "u" :: RAccount.Columns.id
    val uLogin   = "u" :: RAccount.Columns.login
    val uEmail   = "u" :: RAccount.Columns.email
    val sId      = "s" :: RShare.Columns.id
    val sAlias   = "s" :: RShare.Columns.aliasId
    val mAlias   = "m" :: RAliasMember.Columns.aliasId
    val mAccount = "m" :: RAliasMember.Columns.accountId

    val baseQuery =
      Sql
        .selectSimple(
          Seq(aId, aName),
          RAlias.table ++ fr"a" ++
            fr"INNER JOIN" ++ RShare.table ++ fr"s ON" ++ sAlias.is(aId),
          Sql.and(aId.is(aliasId), sId.is(shareId))
        )
        .query[(Ident, String)]
        .option

    val memberQuery: Fragment = {
      val from = RAliasMember.table ++ fr"m" ++
        fr"INNER JOIN" ++ RAccount.table ++ fr"u ON" ++ uId.is(mAccount)
      Sql
        .selectSimple(
          Seq(uLogin, uEmail),
          from,
          Sql.and(mAlias.is(aliasId), uEmail.isNotNull)
        )
    }
    val ownerQuery: Fragment = {
      val from = RAlias.table ++ fr"a" ++
        fr"INNER JOIN" ++ RAccount.table ++ fr"u ON" ++ uId.is(aAccount)
      Sql.selectSimple(
        Seq(uLogin, uEmail),
        from,
        Sql.and(aId.is(aliasId), uEmail.isNotNull)
      )
    }

    (for {
      aliasInfo <- OptionT(baseQuery)
      users <- OptionT.liftF(
        (memberQuery ++ fr"UNION ALL" ++ ownerQuery)
          .query[NotifyData.AccountInfo]
          .to[List]
      )
    } yield NotifyData(aliasInfo._1, aliasInfo._2, users)).value
  }

  def publishIdAndPassword(
      accId: Ident,
      shareId: Ident
  ): ConnectionIO[Option[(Boolean, Ident)]] = {
    val sId    = "s" :: RShare.Columns.id
    val sAcc   = "s" :: RShare.Columns.accountId
    val sPass  = "s" :: RShare.Columns.password
    val pId    = "p" :: RPublishShare.Columns.id
    val pShare = "p" :: RPublishShare.Columns.shareId

    val from =
      RShare.table ++ fr"s INNER JOIN" ++ RPublishShare.table ++ fr"p ON" ++ pShare.is(
        sId
      )

    Sql
      .selectSimple(Seq(sPass, pId), from, Sql.and(sId.is(shareId), sAcc.is(accId)))
      .query[(Option[String], Ident)]
      .option
      .map(_.map(t => (t._1.nonEmpty, t._2)))
  }

  def getEmail(accId: Ident): ConnectionIO[Option[MailAddress]] =
    Sql
      .selectSimple(
        Seq(RAccount.Columns.login, RAccount.Columns.email),
        RAccount.table,
        RAccount.Columns.id.is(accId)
      )
      .query[MailAddress]
      .option
}
