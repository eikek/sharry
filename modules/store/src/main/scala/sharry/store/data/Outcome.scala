package sharry.store.data

sealed trait Outcome[A] {
  def result: A
  def map[B](f: A => B): Outcome[B]
  def isUnmodified: Boolean
  def isCreated: Boolean
}
case class Unmodified[A](result: A) extends Outcome[A] {
  def map[B](f: A => B) = Unmodified(f(result))
  val isUnmodified = true
  val isCreated = false
}
case class Created[A](result: A) extends Outcome[A] {
  def map[B](f: A => B) = Created(f(result))
  def isUnmodified = false
  def isCreated = true
}

object Outcome {
  def unapply[A](o: Outcome[A]): Option[A] = Some(o.result)
}
