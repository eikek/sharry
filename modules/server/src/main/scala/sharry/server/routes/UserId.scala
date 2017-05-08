package sharry.server.routes

import sharry.store.data.Alias

sealed trait UserId {
  def login: String
  def alias: Option[Alias]
  def aliasId: Option[String] = alias.map(_.id)
}
case class Username(login: String) extends UserId {
  val alias = None
}
case class AliasId(a: Alias) extends UserId {
  override val aliasId = Some(a.id)
  val alias = Some(a)
  val login = a.login
}
object UserId {
  def apply(alias: Alias): UserId = AliasId(alias)
  def apply(login: String): UserId = Username(login)
}
