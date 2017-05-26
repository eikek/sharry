package sharry.common

import java.lang.AutoCloseable
import java.io.{InputStream, PipedInputStream, PipedOutputStream}
import java.nio.file.{Files, Path}
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

import fs2.{io, Pipe, Sink, Stream}
import fs2.util.{Effect, Async}

object zip {

  def zip[F[_]](chunkSize: Int)(implicit F: Async[F]): Pipe[F, (String, Stream[F,Byte]), Byte] = {
    val zipped = F.delay {
      val pout = new PipedOutputStream()
      val pin = new PipedInputStream(pout, chunkSize)
      (pin: InputStream, new ZipOutputStream(pout))
    }

    def writeSink(zout: ZipOutputStream): Sink[F, (String, Stream[F,Byte])] = _.flatMap {
      case (name, data) =>
        val newEntry = Stream.eval(F.delay {
          val ze = new ZipEntry(name)
          zout.putNextEntry(ze)
        })
        val writeData = data.to(io.writeOutputStream(F.delay(zout), false))
        val closeEntry =  Stream.eval(F.delay {
          zout.closeEntry
        })
        newEntry ++ writeData ++ closeEntry
    }

    def close(t: AutoCloseable) = F.delay {
      t.close
    }

    in => Stream.eval(zipped).flatMap {
      case (pin, zout) =>
        val fill = in.to(writeSink(zout)).onFinalize(close(zout))
        val read = io.readInputStream(F.delay(pin), chunkSize, false).onFinalize(close(pin))
        fill.drain merge read
    }
  }

  def zip[F[_]](entries: Stream[F, (String, Stream[F, Byte])], chunkSize: Int)(implicit F: Async[F]): Stream[F, Byte] = {
    entries.through(zip(chunkSize))
  }


  def dirEntries[F[_]](dir: Path, include: Path => Boolean = _ => true)(implicit F: Effect[F]): Stream[F, Path] =
    Stream.bracket(F.delay(Files.newDirectoryStream(dir)))(
      dirs => Stream.unfold(dirs.iterator) {
        iter => if (iter.hasNext) Some((iter.next, iter)) else None
      },
      dirs => F.delay(dirs.close)).
      filter(include)

  def dirEntriesRecursive[F[_]](dir: Path, include: Path => Boolean = _ => true)(implicit F: Effect[F]): Stream[F, Path] =
    dirEntries[F](dir).flatMap { p =>
      val r = if (include(p)) Stream.emit(p) else Stream.empty
      if (Files.isDirectory(p)) r ++ dirEntriesRecursive(p, include)
      else r
    }


  def zipDir[F[_]](dir: Path, chunkSize: Int, include: Path => Boolean = _ => true)(implicit F: Async[F]): Stream[F, Byte] = {
    val entries = dirEntriesRecursive(dir, e => !Files.isDirectory(e) && include(e))
    zip(entries.
      map(e => dir.relativize(e).toString -> io.file.readAll(e, chunkSize)), chunkSize)
  }
}
