package sharry.server.authc

import java.nio.channels.AsynchronousChannelGroup
import org.log4s._
import scala.sys.process._
import fs2.{Strategy, Stream, Task}
import cats.syntax.either._
import spinoco.fs2.http
import spinoco.fs2.http.HttpRequest
import spinoco.protocol.http.{HttpMethod, Uri, HttpStatusCode}
import spinoco.protocol.http.header.value.ContentType

import sharry.store.data._
import sharry.server.config._

trait ExternAuthc {
  def verify(login: String, pass: String): Stream[Task,Option[Account]]
}

object ExternAuthc {
  implicit private[this] val logger = getLogger

  def apply(f: (String, String) => Stream[Task,Option[Account]]): ExternAuthc =
    new ExternAuthc {
      def verify(login: String, pass: String) = f(login, pass)
    }

  def apply(cfg: Config)(implicit ACG: AsynchronousChannelGroup, S: Strategy): ExternAuthc = apply {
    List(
      new Command(cfg.authcCommand),
      new Http(cfg.authcHttp),
      configAdmin(cfg.adminAccount)
    )
  }

  def apply(ext: Seq[ExternAuthc]): ExternAuthc = ExternAuthc { (login, pass) =>
    Stream.emits(ext).
      flatMap(_.verify(login, pass)).
      find(_.isDefined).
      lastOr(None)
  }

  final class Command(cfg: AuthcCommand) extends ExternAuthc {
    def verify(login: String, pass: String) =
      if (!cfg.enable) Stream.emit(None)
      else Stream.eval(Task.delay {
        val cmd = cfg.program.map(_.replace("{login}", login).replace("{password}", pass))
        val r = Either.catchOnly[Exception] {
          logger.debug(s"Running external auth command: ${cfg.program.map(_.replace("{login}", login))}")
          Process(cmd).!
        }
        logger.debug(s"Result of command authc: $r")
        if (r == Right(cfg.success)) Some(Account.newExtern(login))
        else None
      })
  }

  final class Http(cfg: AuthcHttp)(implicit ACG: AsynchronousChannelGroup, S: Strategy) extends ExternAuthc {
    def verify(login: String, pass: String) =
      if (!cfg.enable) Stream.emit(None)
      else {
        logger.debug(s"Start with http authentication for $login")
        val makeRequest: Task[HttpRequest[Task]] = Task.delay {

          val replace: String => String =
            _.replace("{login}", login).replace("{password}", pass)

          val req = for {
            url <- Uri.parse(replace(cfg.url)).toEither
            method <- parse(cfg.method, HttpMethod.codec)
            mime <- parse(cfg.contentType, ContentType.codec)
          } yield HttpRequest.get[Task](url).
            withMethod(method).
            withUtf8Body(replace(cfg.body)).
            withContentType(mime)

          req.valueOr { err =>
            logger.error(s"Error making http request for $login: $err")
            throw new Exception(err.toString)
          }
        }

        def execute(req: HttpRequest[Task]): Stream[Task,Option[Account]] = {
          Stream.eval(http.client[Task]()).flatMap { client =>
            client.request(req).map { resp =>
              logger.debug(s"External HTTP auth against ${cfg.url} for $login responds with ${resp.header.status}")
              if (resp.header.status != HttpStatusCode.Ok) None
              else Some(Account.newExtern(login))
            }
          }
        }

        Stream.eval(makeRequest).flatMap(execute)
      }
  }

  def configAdmin(cfg: AdminAccount): ExternAuthc = ExternAuthc { (login, pass) =>
    Stream.emit {
      if (cfg.enable && cfg.login == login && cfg.password == pass)
        Some(Account.newExtern(login).copy(admin = true))
      else
        None
    }
  }

  def disabledAuth(cfg: AuthConfig): ExternAuthc = ExternAuthc { (login, pass) =>
    Stream.emit {
      Some(Account.newExtern(cfg.defaultUser))
    }
  }
}
