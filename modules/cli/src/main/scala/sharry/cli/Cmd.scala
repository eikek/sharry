package sharry.cli

import java.nio.channels.AsynchronousChannelGroup

import fs2.{async, Pipe, Scheduler, Sink, Stream}
import cats.effect.IO
import fs2.async.mutable.Signal
import spinoco.fs2.http
import spinoco.fs2.http.HttpClient
import scala.concurrent.ExecutionContext

import sharry.common.data._
import sharry.cli.config._

trait Cmd { self =>

  def apply(client: HttpClient[IO], progress: Signal[IO, Progress])
      (implicit S: ExecutionContext, SCH: Scheduler): Pipe[IO, Context, Context]

  def >> (next: Cmd): Cmd = new Cmd {
    def apply(client: HttpClient[IO], progress: Signal[IO, Progress])
      (implicit S: ExecutionContext, SCH: Scheduler): Pipe[IO, Context, Context] =
      self.apply(client, progress) andThen next.apply(client, progress)
  }
}

object Cmd {

  val identity: Cmd = new Cmd {
    def apply(client: HttpClient[IO], progress: Signal[IO, Progress])
      (implicit S: ExecutionContext, SCH: Scheduler): Pipe[IO, Context, Context] = s => s
  }


  def apply(f: (HttpClient[IO], Signal[IO, Progress]) => Context => Stream[IO, Context]): Cmd =
    new Cmd {
      def apply(client: HttpClient[IO], progress: Signal[IO, Progress])
        (implicit S: ExecutionContext, SCH: Scheduler): Pipe[IO, Context, Context] = _.flatMap(ctx => f(client, progress)(ctx))
    }

  def choice(f: Context => Cmd): Cmd =
    new Cmd {
      def apply(client: HttpClient[IO], progress: Signal[IO, Progress])
        (implicit S: ExecutionContext, SCH: Scheduler): Pipe[IO, Context, Context] =
        _.flatMap { ctx =>
          val cmd = f(ctx)
          Stream(ctx).covary[IO].through(cmd(client, progress))
        }
    }

  def append(cs: Seq[Cmd]): Cmd =
    cs.reduce(_ >> _)

  def apply(cmd0: Cmd, more: Cmd*): Cmd =
    append(cmd0 +: more)

  def httpClient(implicit ACG: AsynchronousChannelGroup, S: ExecutionContext): Stream[IO, HttpClient[IO]] =
    Stream.eval(http.client[IO]())

  def makeContext(cfg: Config): Stream[IO, Context] =
    Stream(Context(cfg, RemoteConfig.empty))

  def eval(cmd: Cmd, cfg: Config, progress: Signal[IO, Progress])
    (implicit S: ExecutionContext, SCH: Scheduler, ACG: AsynchronousChannelGroup): Stream[IO, Context] = {

    httpClient.flatMap { client =>
      makeContext(cfg).
        through(cmd(client, progress)).
        through(done(client, progress))
    }
  }

  def eval(cmd: Cmd, cfg: Config, sink: Sink[IO, Progress])
    (implicit S: ExecutionContext, SCH: Scheduler, ACG: AsynchronousChannelGroup): Stream[IO, Context] =
    Stream.eval(async.signalOf[IO, Progress](Progress.Init)).
      flatMap { signal =>

        val run = eval(cmd, cfg, signal)
        val prog = signal.discrete.to(sink).compile.drain

        Stream.eval(async.start(prog)).drain ++ run
      }

  def done: Cmd = Cmd { (client, progress) => ctx =>
    import syntax._
    progress.info(Progress.Done(ctx)) ++ Stream(ctx)
  }

  object syntax {

    implicit class ProgressOps(progress: Signal[IO, Progress]) {
      def update(f: Progress => Progress): Stream[IO, Nothing] =
        Stream.eval(progress.modify(f)).drain

      def info(value: Progress): Stream[IO, Nothing] =
        update(_ => value)
    }
  }
}
