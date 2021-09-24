package sharry.common

import cats.implicits._

case class AccountId(id: Ident, userLogin: Ident, admin: Boolean, alias: Option[Ident]) {

  def asString =
    alias match {
      case Some(a) =>
        s"${id.id}/${userLogin.id}/$admin/${a.id}"
      case None =>
        s"${id.id}/${userLogin.id}/$admin"
    }

}

object AccountId {

  val empty: AccountId =
    AccountId(Ident.empty, Ident.empty, false, None)

  def parse(str: String): Either[String, AccountId] = {
    val parts = str.split('/').toList.appended("").take(4)

    parts match {
      case List(id, acc, adm, ali) =>
        for {
          aid <- Ident.fromString(id)
          name <- Ident.fromString(acc)
          flag <- Either.catchNonFatal(adm.trim.toBoolean).leftMap(_.getMessage)
          alias <- Ident.fromString(ali)
        } yield AccountId(aid, name, flag, Option(alias).filter(_.nonEmpty))
      case _ =>
        Left(s"Invalid accountId: $str")
    }
  }

}
