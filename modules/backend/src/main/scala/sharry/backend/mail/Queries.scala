package sharry.backend.mail

import sharry.common._
import sharry.store.doobie.DoobieMeta._
import sharry.store.doobie._
import sharry.store.records._

import doobie._
import doobie.implicits._
import emil.MailAddress

object Queries {

  def resolveAlias(
      aliasId: Ident,
      shareId: Ident
  ): ConnectionIO[Option[(RAlias, RAccount)]] = {
    val aId      = "a" :: RAlias.Columns.id
    val aAccount = "a" :: RAlias.Columns.account
    val uId      = "u" :: RAccount.Columns.id
    val sId      = "s" :: RShare.Columns.id
    val sAlias   = "s" :: RShare.Columns.aliasId

    val from = RAlias.table ++ fr"a INNER JOIN" ++
      RAccount.table ++ fr"u ON" ++ uId.is(aAccount) ++ fr"INNER JOIN" ++
      RShare.table ++ fr"s ON" ++ sAlias.is(aliasId)

    Sql
      .selectSimple(
        RAlias.Columns.all.map("a" :: _) ++ RAccount.Columns.all.map("u" :: _),
        from,
        Sql.and(aId.is(aliasId), sId.is(shareId))
      )
      .query[(RAlias, RAccount)]
      .option
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
