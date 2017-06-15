package sharry.docs.md

trait TocAccess {

  // the abstract method is implemented by an sbt generated object `toc.scala`
  def contents: List[(String, String, String, Long)]

  def find(path: String): Option[ManualPage] =
    contents.find(_._1 == path).
      flatMap {
        case (path, chs, mime, size) =>
          Option(getClass.getResource(path)).
            map(url => ManualPage(path, chs, mime, size, url))
      }
}
