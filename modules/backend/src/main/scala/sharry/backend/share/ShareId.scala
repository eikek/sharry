package sharry.backend.share

import sharry.common._

sealed trait ShareId {

  def fold[A](f: ShareId.PublicId => A, g: ShareId.PrivateId => A): A
}

object ShareId {

  def publish(id: Ident): ShareId =
    PublicId(id)

  def secured(id: Ident, acc: AccountId): ShareId =
    PrivateId(id, acc)

  case class PublicId(id: Ident) extends ShareId {
    def fold[A](f: ShareId.PublicId => A, g: ShareId.PrivateId => A): A =
      f(this)
  }

  case class PrivateId(id: Ident, account: AccountId) extends ShareId {
    def fold[A](f: ShareId.PublicId => A, g: ShareId.PrivateId => A): A =
      g(this)
  }
}
