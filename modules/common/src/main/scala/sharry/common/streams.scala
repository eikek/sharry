package sharry.common

import java.io.InputStream
import scodec.bits.ByteVector
import fs2.{io, Chunk, Pipe, Stream}
import cats.effect.IO
import cats.effect.Sync
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

  def readIs[F[_]](is: F[InputStream], size: Size)(implicit F: Sync[F]): Stream[F, Byte] =
    io.readInputStream(is, size.bytes, true) //.rechunk(size.bytes, true)

  def noWeirdChars[F[_]]: Pipe[F, Byte, Byte] = {
    val valid: Byte => Boolean =
      b => b > 31 || b < 0 || b == 13 || b == 10 || b == 9
    _.filter(valid)
  }

  def optionToEmpty[F[_], I]: Pipe[F, Option[I], I] =
    _.flatMap {
      case Some(i) => Stream.emit(i)
      case None => Stream.empty
    }

  def ifEmpty[F[_],A](s: Stream[F,A]): Pipe[F,A,A] = in => {
    val sn = in.noneTerminate
    sn.head.flatMap {
      case Some(a) => Stream.emit(a) ++ sn.tail.unNoneTerminate
      case None => s
    }
  }

  def log[F[_], A](f: Logger => Unit)(implicit l: Logger, F: Sync[F]): Pipe[F, A, A] =
    s => s ++ slog(f)

  def logEach[F[_], A](f: (A, Logger) => Unit)(implicit l: Logger, F: Sync[F]): Pipe[F,A,A] =
    _.flatMap(a => slog(f.curried(a)) ++ Stream.emit(a))

  def logEmpty[F[_], A](f: Logger => Unit)(implicit l: Logger, F: Sync[F]): Pipe[F,A,A] =
    ifEmpty(slog(f))

  def slog[F[_]](f: Logger => Unit)(implicit l: Logger, F: Sync[F]): Stream[F, Nothing] = {
    Stream.eval(F.delay{ f(l) }).drain
  }

  def slogT(f: Logger => Unit)(implicit l: Logger): Stream[IO, Nothing] =
    slog[IO](f)
}
