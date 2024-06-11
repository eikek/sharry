package sharry.common.syntax

import cats.implicits.*

import io.circe.Decoder
import io.circe.parser.*

trait StringSyntax {

  implicit final class EvenMoreStringOps(s: String) {

    def asNonBlank: Option[String] =
      Option(s).filter(_.trim.nonEmpty)

    def parseJsonAs[A](implicit d: Decoder[A]): Either[Throwable, A] =
      for {
        json <- parse(s).leftMap(_.underlying)
        value <- json.as[A]
      } yield value
  }

}
