package sharry.common

import java.io.InputStream
import scodec.bits.ByteVector
import fs2.{io, Chunk, Handle, Pipe, Pull, Stream, Task}
import fs2.util.Suspendable
import org.log4s._

import sizes._

/** Some utility for fs2.Stream */
object streams {

  def toByteChunks[F[_]]: Pipe[F, Byte, ByteVector] =
    _.chunks.map(c => ByteVector.view(c.toArray))

  /** Reads all bytes into a single ByteVector */
  def append[F[_]]: Pipe[F, Byte, ByteVector] =
    _.through(toByteChunks).fold(ByteVector.empty)(_ ++ _)

  def unchunk[F[_]]: Pipe[F, ByteVector, Byte] =
    _.flatMap(bv => Stream.chunk(Chunk.bytes(bv.toArray)))

  // def toInputStream[F[_]](implicit F: Async[F]): Pipe[F, ByteVector, InputStream] =
  //   _.through(toByteArray).through(io.toInputStream)

  def readIs[F[_]](is: F[InputStream], size: Size)(implicit F: Suspendable[F]): Stream[F, Byte] =
    io.readInputStream(is, size.bytes, true).rechunkN(size.bytes, true)

  def toBase64[F[_]]: Pipe[F, Byte, ByteVector] =
    _.vectorChunkN(3456)
      .map(v => ByteVector(v))
      .map(base64.basic.encode)

  def toBase64String[F[_]]: Pipe[F, Byte, String] =
    _.through(toBase64)
      .map(_.decodeAscii.right.get)
      .fold("")(_ + _)

  def noWeirdChars[F[_]]: Pipe[F, Byte, Byte] = {
    val valid: Byte => Boolean =
      b => b > 31 || b < 0 || b == 13 || b == 10 || b == 9
    _.filter(valid)
  }

  /** Apply `f` to the last element */
  def mapLast[F[_], I](f: I => I): Pipe[F, I, I] = {
    def go(last: Chunk[I]): Handle[F,I] => Pull[F,I,Unit] = {
      _.receiveOption {
        case Some((chunk, h)) => Pull.output(last) >> go(chunk)(h)
        case None =>
          val k = f(last(last.size-1))
          val init = last.take(last.size-1).toVector
          Pull.output(Chunk.indexedSeq(init :+ k))
      }
    }
    _.pull { _.receiveOption {
      case Some((c, h)) => go(c)(h)
      case None => Pull.done
    }}
  }

  def headOption[F[_], I]: Pipe[F, I, Option[I]] =
    _.pull {
      _.receive1Option {
        case Some((e, h)) => Pull.output1(Some(e)) >> Pull.done
        case None => Pull.output1(None) >> Pull.done
      }
    }

  def optionToEmpty[F[_], I]: Pipe[F, Option[I], I] =
    _.flatMap {
      case Some(i) => Stream.emit(i)
      case None => Stream.empty
    }

  def ifEmpty[F[_], I](s: Stream[F, I]): Pipe[F, I, I] =
    _.pull { h =>
      h.receiveOption {
        case Some((c, h)) => Pull.output(c) >> h.echo
        case None => Pull.outputs(s) >> Pull.done
      }
    }

  def log[F[_], A](f: Logger => Unit)(implicit l: Logger, F: Suspendable[F]): Pipe[F, A, A] =
    s => s ++ slog(f)

  def logEach[F[_], A](f: (A, Logger) => Unit)(implicit l: Logger, F: Suspendable[F]): Pipe[F,A,A] =
    _.flatMap(a => slog(f.curried(a)) ++ Stream.emit(a))

  def logEmpty[F[_], A](f: Logger => Unit)(implicit l: Logger, F: Suspendable[F]): Pipe[F,A,A] =
    ifEmpty(slog(f))

  def slog[F[_]](f: Logger => Unit)(implicit l: Logger, F: Suspendable[F]): Stream[F, Nothing] = {
    Stream.eval(F.delay{ f(l) }).drain
  }

  def slogT(f: Logger => Unit)(implicit l: Logger): Stream[Task, Nothing] =
    slog[Task](f)
}
