package sharry.common

import java.io.OutputStream
import java.nio.file.{Files, Path}
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import scala.concurrent.ExecutionContext

import fs2.{async, io, Chunk, Pipe, Sink, Stream, Segment}
import scala.concurrent.SyncVar
import cats.effect.{Effect, IO}

object zip {

  /** This implemenation is from @wedens and @pchlupacek
    * https://gitter.im/functional-streams-for-scala/fs2?at=592affb6c4d73f445af10e45
    * http://lpaste.net/9043000581702025216
    */
  def zip[F[_]](chunkSize: Int)(implicit F: Effect[F], EC: ExecutionContext): Pipe[F, (String, Stream[F,Byte]), Byte] = entries =>
    Stream.eval(fs2.async.synchronousQueue[F, Option[Chunk[Byte]]]).flatMap { q =>
      def writeEntry(zos: ZipOutputStream): Sink[F, (String, Stream[F, Byte])] =
        _.flatMap {
          case (name, data) =>
            val mkEntry = Stream.eval(F.delay {
              val ze = new ZipEntry(name)
              zos.putNextEntry(ze)
            })
            val writeData = data.to(
              io.writeOutputStream(
                F.delay(zos),
                closeAfterUse = false))
            val closeEntry = Stream.eval(F.delay(zos.closeEntry()))

            mkEntry ++ writeData ++ closeEntry
        }

      Stream.suspend {
        val os = new OutputStream {
          private def enqueueChunkSync(a: Option[Chunk[Byte]]) = {
            val done = new SyncVar[Either[Throwable, Unit]]
            //F.unsafeRunAsync(q.enqueue1(a))(done.put)
            async.unsafeRunAsync(q.enqueue1(a))(e => IO(done.put(e)))
            done.get.fold(throw _, identity)
          }

          @annotation.tailrec
          private def addChunk(c: Chunk[Byte]): Unit = {
            val free = chunkSize - chunk.size
            if (c.size > free) {
              enqueueChunkSync(Some((Segment.chunk(chunk) ++ Segment.chunk(c.take(free))).force.toChunk))
              chunk = Chunk.empty
              addChunk(c.drop(free))
            } else {
              chunk = (Segment.chunk(chunk) ++ Segment.chunk(c)).force.toChunk
            }
          }


          private var chunk: Chunk[Byte] = Chunk.empty

          override def close(): Unit = {
            enqueueChunkSync(Some(chunk))
            chunk = Chunk.empty
            enqueueChunkSync(None)
          }

          override def write(bytes: Array[Byte]): Unit =
            addChunk(Chunk.bytes(bytes))
          override def write(bytes: Array[Byte], off: Int, len: Int): Unit =
            addChunk(Chunk.bytes(bytes, off, len))
          override def write(b: Int): Unit =
            addChunk(Chunk.singleton(b.toByte))
        }

        val zos = new ZipOutputStream(os)
        val write = entries.to(writeEntry(zos))
          .onFinalize(F.delay(zos.close()))

        q.dequeue
         .unNoneTerminate
         .flatMap(Stream.chunk(_))
         .concurrently(write)
      }
    }


  def zip[F[_]](entries: Stream[F, (String, Stream[F, Byte])], chunkSize: Int)(implicit F: Effect[F], EC: ExecutionContext): Stream[F, Byte] = {
    entries.through(zip(chunkSize))
  }


  def dirEntries[F[_]](dir: Path, include: Path => Boolean = _ => true)(implicit F: Effect[F]): Stream[F, Path] =
    Stream.bracket(F.delay(Files.newDirectoryStream(dir)))(
      dirs => Stream.unfold(dirs.iterator) {
        iter => if (iter.hasNext) Some((iter.next, iter)) else None
      },
      dirs => F.delay(dirs.close)).
      filter(include)

  def dirEntriesRecursive[F[_]](dir: Path, include: Path => Boolean = _ => true)(implicit F: Effect[F],EC: ExecutionContext): Stream[F, Path] =
    dirEntries[F](dir).flatMap { p =>
      val r = if (include(p)) Stream.emit(p) else Stream.empty
      if (Files.isDirectory(p)) r ++ dirEntriesRecursive(p, include)
      else r
    }


  def zipDir[F[_]](dir: Path, chunkSize: Int, include: Path => Boolean = _ => true)(implicit F: Effect[F], EC: ExecutionContext): Stream[F, Byte] = {
    val entries = dirEntriesRecursive(dir, e => !Files.isDirectory(e) && include(e))
    zip(entries.
      map(e => dir.relativize(e).toString -> io.file.readAll(e, chunkSize)), chunkSize)
  }
}
