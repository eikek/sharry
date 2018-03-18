package sharry.common

import java.io.ByteArrayInputStream
import java.util.zip.ZipInputStream
import org.scalatest._
import fs2.{io, Pure, Stream}
import cats.effect.IO
import scala.concurrent.ExecutionContext.Implicits.global

import sharry.common.rng._

class ZipSpec extends FlatSpec with Matchers {

  "zip" should "add entries with data" in {

    val data = Stream.emits[(String, Stream[IO,Byte])](Seq(
      ("file1.txt", Stream.emit(Gen.bytes(100).generate()).through(streams.unchunk)),
      ("file2.txt", Stream.emit(Gen.bytes(100).generate()).through(streams.unchunk))
    ))

    val zipped = data.
      covary[IO].
      through(zip.zip(8192)).
      runLog.
      unsafeRunSync

    val zin = new ZipInputStream(new ByteArrayInputStream(zipped.toArray))
    val e0 = zin.getNextEntry
    e0.getName should be ("file1.txt")
    val bytes0 = io.readInputStream[IO](IO(zin), 500, false).runLog.unsafeRunSync
    bytes0 should be (data.toList.head._2.runLog.unsafeRunSync)

    val e1 = zin.getNextEntry
    e1.getName should be ("file2.txt")
    val bytes1 = io.readInputStream[IO](IO(zin), 500, false).runLog.unsafeRunSync
    bytes1 should be (data.toList.apply(1)._2.runLog.unsafeRunSync)

    zin.getNextEntry should be (null)
    zin.close
  }
}
