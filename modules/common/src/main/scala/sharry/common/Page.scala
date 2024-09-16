package sharry.common

final case class Page(limit: Int, offset: Int):
  def next: Page = Page(limit, offset + limit)
  def prev: Page = Page(limit, math.max(0, offset - limit))
  def capped(max: Int): Page = copy(limit = math.min(max, limit))

object Page:

  def one(size: Int): Page = Page(size, 0)

  def page(pageNum: Int, pageSize: Int): Page =
    if (pageNum <= 1) one(pageSize)
    else Page(pageSize, (pageNum - 1) * pageSize)
