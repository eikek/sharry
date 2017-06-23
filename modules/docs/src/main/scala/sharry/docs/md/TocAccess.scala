package sharry.docs.md

trait TocAccess {

  // the abstract method is implemented by an sbt generated object `toc.scala`
  def contents: List[(String, String, String, Long)]

  lazy val names = contents.map(_._1)

  def find(path: String): Option[ManualPage] =
    contents.find(_._1 == path).
      flatMap {
        case (path, chs, mime, size) =>
          Option(getClass.getResource(path)).
            map(url => ManualPage(path, chs, mime, size, url))
      }
}
