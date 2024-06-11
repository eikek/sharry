package sharry.common.syntax

import cats.effect.Sync
import cats.implicits.*
import fs2.Stream

import io.circe.*
import io.circe.parser.*

trait StreamSyntax {

  implicit class StringStreamOps[F[_]](s: Stream[F, String]) {

    def parseJsonAs[A](implicit d: Decoder[A], F: Sync[F]): F[Either[Throwable, A]] =
      s.fold("")(_ + _)
        .compile
        .last
        .map(optStr =>
          for {
            str <-
              optStr
                .map(_.trim)
                .toRight(new Exception("Empty string cannot be parsed into a value"))
            json <- parse(str).leftMap(_.underlying)
            value <- json.as[A]
          } yield value
        )

  }

}
