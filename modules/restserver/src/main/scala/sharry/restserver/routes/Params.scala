package sharry.restserver.routes

import sharry.common.Page as CPage

import org.http4s.dsl.impl.OptionalQueryParamDecoderMatcher

object Params:

  object Query extends OptionalQueryParamDecoderMatcher[String]("q")

  object Page {
    def unapply(params: Map[String, collection.Seq[String]]): Option[CPage] =
      val pageNum = params.get("page").flatMap(_.headOption).flatMap(_.toIntOption) match
        case Some(n) if n >= 1 => n
        case _                 => 1

      val pageSize =
        params.get("pageSize").flatMap(_.headOption).flatMap(_.toIntOption) match
          case Some(n) if n >= 1 => n
          case _                 => 100

      Some(CPage.page(pageNum, pageSize))
  }
