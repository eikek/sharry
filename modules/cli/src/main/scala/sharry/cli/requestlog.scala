package sharry.cli

import org.log4s._
import fs2.{Stream, Task}
import spinoco.fs2.http._

trait requestlog {

  def logger: Logger

  def log(f: Logger => Unit): Stream[Task, Unit] =
    Stream.eval(Task.delay(f(logger)))


  implicit class HttpClientLogOps(client: HttpClient[Task]) {

    def dorequest(req: HttpRequest[Task]): Stream[Task, HttpResponse[Task]] =
      for {
        _ <- log(_.trace(s"Request: $req"))
        resp <- client.request(req)
        _ <- log(_.trace(s"Response: $resp"))
      } yield resp
  }
}
