package sharry.store.records

import cats.data.OptionT

import sharry.common.*
import sharry.store.doobie.*
import sharry.store.doobie.DoobieMeta.*

import doobie.*
import doobie.implicits.*

case class RPublishShare(
    id: Ident,
    shareId: Ident,
    enabled: Boolean,
    views: Int,
    lastAccess: Option[Timestamp],
    publishDate: Timestamp,
    publishUntil: Timestamp,
    created: Timestamp
)

object RPublishShare {

  val table = fr"publish_share"

  object Columns {

    val id = Column("id")
    val shareId = Column("share_id")
    val enabled = Column("enabled")
    val views = Column("views")
    val lastAccess = Column("last_access")
    val publishDate = Column("publish_date")
    val publishUntil = Column("publish_until")
    val created = Column("created")

    val all =
      List(id, shareId, enabled, views, lastAccess, publishDate, publishUntil, created)
  }

  import Columns._

  def insert(v: RPublishShare): ConnectionIO[Int] =
    Sql
      .insertRow(
        table,
        all,
        fr"${v.id},${v.shareId},${v.enabled},${v.views}," ++
          fr"${v.lastAccess},${v.publishDate},${v.publishUntil}," ++
          fr"${v.created}"
      )
      .update
      .run

  def update(v: RPublishShare): ConnectionIO[Int] =
    Sql
      .updateRow(
        table,
        shareId.is(v.shareId),
        Sql.commas(
          id.setTo(v.id),
          enabled.setTo(v.enabled),
          views.setTo(v.views),
          lastAccess.setTo(v.lastAccess),
          publishDate.setTo(v.publishDate),
          publishUntil.setTo(v.publishUntil)
        )
      )
      .update
      .run

  def existsByShare(share: Ident): ConnectionIO[Boolean] =
    Sql.selectCount(id, table, shareId.is(share)).query[Int].unique.map(_ > 0)

  def findByShare(share: Ident): ConnectionIO[Option[RPublishShare]] =
    Sql.selectSimple(all, table, shareId.is(share)).query[RPublishShare].option

  def initialInsert[F[_]](share: Ident): ConnectionIO[RPublishShare] =
    for {
      now <- Timestamp.current[ConnectionIO]
      id <- Ident.randomId[ConnectionIO]
      validity <- RShare.getDuration(share)
      record = RPublishShare(
        id,
        share,
        enabled = true,
        0,
        None,
        now,
        now.plus(validity),
        now
      )
      _ <- insert(record)
    } yield record

  def updateValidityTime(share: Ident, validity: Duration): ConnectionIO[Int] =
    (for {
      published <- OptionT(
        Sql
          .selectSimple(
            Seq(publishDate),
            table,
            Sql.and(shareId.is(share), enabled.is(true))
          )
          .query[Timestamp]
          .option
      )
      n <- OptionT.liftF(
        Sql
          .updateRow(
            table,
            shareId.is(share),
            publishUntil.setTo(published.plus(validity))
          )
          .update
          .run
      )
    } yield n).getOrElse(0)

  def update(share: Ident, enable: Boolean, reuseId: Boolean): ConnectionIO[Int] =
    for {
      nid <- Ident.randomId[ConnectionIO]
      validity <- RShare.getDuration(share)
      now <- Timestamp.current[ConnectionIO]
      sets =
        Seq(enabled.setTo(enable)) ++
          (if (enable) Seq(publishDate.setTo(now), publishUntil.setTo(now.plus(validity)))
           else Seq.empty) ++
          (if (reuseId) Seq.empty else Seq(id.setTo(nid)))
      frag <- Sql.updateRow(table, shareId.is(share), Sql.commas(sets)).update.run
    } yield frag

}
