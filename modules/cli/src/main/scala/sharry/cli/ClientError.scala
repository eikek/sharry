package sharry.cli

import cats.data.NonEmptyList
import cats.Semigroup
import fs2.{Pipe, Stream, Task}
import spinoco.fs2.http.HttpResponse

case class ClientError(reasons: NonEmptyList[String]) extends RuntimeException(reasons.toList.mkString(", ")) {

  override def toString(): String =
    s"ClientError($reasons)"

  def ::(reason: String) =
    ClientError(reason :: reasons)

  def ++(next: ClientError): ClientError =
    ClientError(reasons concat next.reasons)
}


object ClientError {

  def apply(reason: String, more: String*): ClientError =
    ClientError(NonEmptyList(reason, more.toList))

  def fromThrowable(e: Throwable): ClientError = {
    val err = ClientError(e.getMessage)
    err.setStackTrace(e.getStackTrace)
    err
  }

  def fromResponse(resp: HttpResponse[Task]): Task[Option[ClientError]] =
    if (resp.header.status.isSuccess) Task.now(None)
    else resp.bodyAs[Map[String,String]].
        map(_.map(_.apply("message"))).
        map(_.fold(_ => s"Server responded with ${resp.header.status}: ${resp.bodyAsString}", identity)).
        map(str => Some(ClientError(str)))

  /** Pass the response if successful, otherwise fail the stream with some exception */
  def onSuccess: Pipe[Task, HttpResponse[Task], HttpResponse[Task]] =
    s => for {
      resp <- s
      err <- Stream.eval(fromResponse(resp))
      r <- err.map(Stream.fail(_)).getOrElse(Stream(resp))
    } yield r

  implicit val semigroup: Semigroup[ClientError] =
    new Semigroup[ClientError] {
      def combine(e1: ClientError, e2: ClientError): ClientError =
        ClientError(implicitly[Semigroup[NonEmptyList[String]]].combine(e1.reasons, e2.reasons))
    }
}
