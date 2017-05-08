package sharry.store

case class Limit(limit: Int, offset: Int)

object Limit {
  def offset(n: Int) = Limit(0, n)
  def limit(n: Int) = Limit(n, 0)
  def limitOffset(limit: Int, offset: Int) = Limit(limit, offset)

  def page(size: Int, num: Int): Limit = {
    if (num <= 1) limit(size)
    else limitOffset(size, (num -1) * size)
  }
}
