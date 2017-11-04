package sharry.cli

import java.nio.channels.AsynchronousChannelGroup

import fs2.{async, Pipe, Scheduler, Sink, Stream, Strategy, Task}
import fs2.async.mutable.Signal
import spinoco.fs2.http
import spinoco.fs2.http.HttpClient

import sharry.common.data._
import sharry.cli.config._

trait Cmd { self =>

  def apply(client: HttpClient[Task], progress: Signal[Task, Progress])
      (implicit S: Strategy, SCH: Scheduler): Pipe[Task, Context, Context]

  def >> (next: Cmd): Cmd = new Cmd {
    def apply(client: HttpClient[Task], progress: Signal[Task, Progress])
      (implicit S: Strategy, SCH: Scheduler): Pipe[Task, Context, Context] =
      self.apply(client, progress) andThen next.apply(client, progress)
  }
}

object Cmd {

  val identity: Cmd = new Cmd {
    def apply(client: HttpClient[Task], progress: Signal[Task, Progress])
      (implicit S: Strategy, SCH: Scheduler): Pipe[Task, Context, Context] = s => s
  }


  def apply(f: (HttpClient[Task], Signal[Task, Progress]) => Context => Stream[Task, Context]): Cmd =
    new Cmd {
      def apply(client: HttpClient[Task], progress: Signal[Task, Progress])
        (implicit S: Strategy, SCH: Scheduler): Pipe[Task, Context, Context] = _.flatMap(ctx => f(client, progress)(ctx))
    }

  def choice(f: Context => Cmd): Cmd =
    new Cmd {
      def apply(client: HttpClient[Task], progress: Signal[Task, Progress])
        (implicit S: Strategy, SCH: Scheduler): Pipe[Task, Context, Context] =
        _.flatMap { ctx =>
          val cmd = f(ctx)
          Stream(ctx).through(cmd(client, progress))
        }
    }

  def append(cs: Seq[Cmd]): Cmd =
    cs.reduce(_ >> _)

  def apply(cmd0: Cmd, more: Cmd*): Cmd =
    append(cmd0 +: more)

  def httpClient(implicit ACG: AsynchronousChannelGroup, S: Strategy): Stream[Task, HttpClient[Task]] =
    Stream.eval(http.client[Task]())

  def makeContext(cfg: Config): Stream[Task, Context] =
    Stream(Context(cfg, RemoteConfig.empty))

  def eval(cmd: Cmd, cfg: Config, progress: Signal[Task, Progress])
    (implicit S: Strategy, SCH: Scheduler, ACG: AsynchronousChannelGroup): Stream[Task, Context] = {

    httpClient.flatMap { client =>
      makeContext(cfg).
        through(cmd(client, progress)).
        through(done(client, progress))
    }
  }

  def eval(cmd: Cmd, cfg: Config, sink: Sink[Task, Progress])
    (implicit S: Strategy, SCH: Scheduler, ACG: AsynchronousChannelGroup): Stream[Task, Context] =
    Stream.eval(async.signalOf[Task, Progress](Progress.Init)).
      flatMap { signal =>

        val run = eval(cmd, cfg, signal)
        val prog = signal.discrete.to(sink).run

        Stream.eval(Task.start(prog)).drain ++ run
      }

  def done: Cmd = Cmd { (client, progress) => ctx =>
    import syntax._
    progress.info(Progress.Done(ctx)) ++ Stream(ctx)
  }

  object syntax {

    implicit class ProgressOps(progress: Signal[Task, Progress]) {
      def update(f: Progress => Progress): Stream[Task, Nothing] =
        Stream.eval(progress.modify(f)).drain

      def info(value: Progress): Stream[Task, Nothing] =
        update(_ => value)
    }
  }
}
