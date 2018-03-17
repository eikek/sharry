package sharry.cli

import org.log4s._
import fs2.Stream
import cats.effect.IO
import spinoco.fs2.http._
import spinoco.protocol.http.header.`User-Agent`
import spinoco.protocol.http.header.value.AgentVersion

import sharry.common.version

trait requestlog {

  def logger: Logger

  def log(f: Logger => Unit): Stream[IO, Unit] =
    Stream.eval(IO(f(logger)))


  implicit class HttpClientLogOps(client: HttpClient[IO]) {
    def dorequest(req: HttpRequest[IO]): Stream[IO, HttpResponse[IO]] = {
      val rreq = req.
        appendHeader(`User-Agent`(AgentVersion(s"Sharry Cli ${version.longVersion}")))
      for {
        _ <- log(_.trace(s"Request: $rreq"))
        resp <- client.request(rreq)
        _ <- log(_.trace(s"Response: $resp"))
      } yield resp
    }
  }
}
