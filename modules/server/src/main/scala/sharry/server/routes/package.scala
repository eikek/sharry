package sharry.server

import fs2.Task
import spinoco.fs2.http.body.{BodyDecoder, BodyEncoder}
import spinoco.protocol.http.header.value.{ContentType, MediaType}
import spinoco.fs2.http.routing.{body => rbody}
import scodec.{Attempt, Err}
import scodec.bits.ByteVector
import io.circe.{Json, Encoder, Decoder}, io.circe.parser._, io.circe.syntax._

package object routes {

  private def parseJson(b: ByteVector): Attempt[Json] =
    for {
      str <- b.decodeUtf8.attempt
      json <- parse(str).attempt
    } yield json

  private def decodeJson[A](b: ByteVector)(implicit dec: Decoder[A]): Attempt[A] =
    for {
      json <- parseJson(b)
      a <- dec.decodeJson(json).attempt
    } yield a


  implicit def jsonBodyDecoder[A](implicit jd: Decoder[A]): BodyDecoder[A] =
    BodyDecoder { (bs, ct) =>
      if (ct.mediaType == MediaType.`application/json`) decodeJson(bs)
      else Attempt.failure(Err(s"Unsupported content type: $ct"))
    }

  implicit def jsonBodyEncoder[A](implicit je: Encoder[A]): BodyEncoder[A] =
    BodyEncoder(ContentType(MediaType.`application/json`, None, None)) { a =>
      ByteVector.encodeUtf8(a.asJson.spaces2).attempt
    }

  def jsonBody[A](implicit d: BodyDecoder[A]) = rbody[Task].as[A]

  implicit final class EitherAttempt[A, B](e: Either[A,B]) {
    def attempt: Attempt[B] = Attempt.fromEither(e.left.map(a => Err(a.toString)))
  }

  implicit final class StringOps(s: String) {
    def asNonEmpty: Option[String] = Option(s).map(_.trim).filter(_.nonEmpty)
  }
}
