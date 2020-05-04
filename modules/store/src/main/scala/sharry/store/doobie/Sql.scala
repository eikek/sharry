package sharry.store.doobie

import doobie._
import doobie.implicits._
import sharry.common.Timestamp

object Sql {

  def commas(fs: Seq[Fragment]): Fragment =
    fs.reduce(_ ++ Fragment.const(",") ++ _)

  def commas(fa: Fragment, fas: Fragment*): Fragment =
    commas(fa :: fas.toList)

  def currentTime: ConnectionIO[Timestamp] =
    Timestamp.current[ConnectionIO]

  def insertRow(table: Fragment, cols: List[Column], vals: Fragment): Fragment =
    Fragment.const("INSERT INTO ") ++ table ++ Fragment.const(" (") ++
      commas(cols.map(_.f)) ++ Fragment.const(") VALUES (") ++ vals ++ Fragment.const(")")

  def updateRow(table: Fragment, where: Fragment, setter: Fragment): Fragment =
    Fragment.const("UPDATE ") ++ table ++ Fragment.const(" SET ") ++ setter ++ this.where(
      where
    )

  def selectSimple(cols: Seq[Column], table: Fragment, where: Fragment): Fragment =
    selectSimple(commas(cols.map(_.f)), table, where)

  def selectSimple(cols: Fragment, table: Fragment, where: Fragment): Fragment =
    Fragment.const("SELECT ") ++ cols ++
      Fragment.const(" FROM ") ++ table ++ this.where(where)

  def selectCount(col: Column, table: Fragment, where: Fragment): Fragment =
    Fragment.const("SELECT COUNT(") ++ col.f ++ Fragment.const(") FROM ") ++ table ++ this
      .where(
        where
      )

  def deleteFrom(table: Fragment, where: Fragment): Fragment =
    fr"DELETE FROM" ++ table ++ this.where(where)

  def where(fa: Fragment): Fragment =
    if (isEmpty(fa)) Fragment.empty
    else Fragment.const(" WHERE ") ++ fa

  def isEmpty(fragment: Fragment): Boolean =
    Fragment.empty.toString() == fragment.toString()

  def and(fs: Seq[Fragment]): Fragment =
    Fragment.const(" (") ++ fs
      .filter(f => !isEmpty(f))
      .reduce(_ ++ Fragment.const(" AND ") ++ _) ++ Fragment.const(") ")

  def and(f0: Fragment, fs: Fragment*): Fragment =
    and(f0 :: fs.toList)

  def or(fs: Seq[Fragment]): Fragment =
    Fragment.const(" (") ++ fs.reduce(_ ++ Fragment.const(" OR ") ++ _) ++ Fragment.const(
      ") "
    )
  def or(f0: Fragment, fs: Fragment*): Fragment =
    or(f0 :: fs.toList)

}
