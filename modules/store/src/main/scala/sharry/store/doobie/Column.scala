package sharry.store.doobie

import doobie._
import doobie.implicits._
import sharry.common.CIIdent

case class Column(name: String, ns: String = "", alias: String = "") {

  val f = {
    val col =
      if (ns.isEmpty) Fragment.const(name)
      else Fragment.const(ns + "." + name)
    if (alias.isEmpty) col
    else col ++ fr"as" ++ Fragment.const(alias)
  }

  def ::(ns: String): Column =
    Column(name, ns, alias)

  def as(alias: String): Column =
    Column(name, ns, alias)

  def is[A: Put](value: A): Fragment =
    f ++ fr" = $value"

  def is(value: CIIdent)(implicit P: Put[CIIdent]): Fragment =
    fr"LOWER(" ++ f ++ sql") = $value"

  def isNot[A: Put](value: A): Fragment =
    f ++ fr"<> $value"

  def is[A: Put](ov: Option[A]): Fragment =
    ov match {
      case Some(v) => f ++ fr" = $v"
      case None    => f ++ fr"is null"
    }

  def isNull: Fragment =
    f ++ fr"is null"

  def is(c: Column): Fragment =
    f ++ fr"=" ++ c.f

  def like(value: String): Fragment = {
    val str = value.toLowerCase
    fr"LOWER(" ++ f ++ fr") LIKE $str"
  }

  def isGt[A: Put](a: A): Fragment =
    f ++ fr"> $a"

  def isLt[A: Put](a: A): Fragment =
    f ++ fr"< $a"

  def isGt(c: Column): Fragment =
    f ++ fr">" ++ c.f

  def increment[A: Put](a: A): Fragment =
    f ++ fr"=" ++ f ++ fr"+ $a"

  def setTo[A: Put](value: A): Fragment =
    is(value)

  def setTo[A: Put](va: Option[A]): Fragment =
    f ++ fr" = $va"

}
