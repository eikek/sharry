package sharry.common

import java.io.ByteArrayInputStream
import java.util.zip.ZipInputStream
import org.scalatest._
import fs2.{io, Pure, Strategy, Stream, Task}

import sharry.common.rng._

class ZipSpec extends FlatSpec with Matchers {
  implicit val S = Strategy.fromCachedDaemonPool("test")

  "zip" should "add entries with data" in {

    val data = Stream.emits[Pure, (String, Stream[Task,Byte])](Seq(
      ("file1.txt", Stream.emit(Gen.bytes(100).generate()).through(streams.unchunk)),
      ("file2.txt", Stream.emit(Gen.bytes(100).generate()).through(streams.unchunk))
    ))

    val zipped = data.
      covary[Task].
      through(zip.zip(8192)).
      runLog.
      unsafeRun

    val zin = new ZipInputStream(new ByteArrayInputStream(zipped.toArray))
    val e0 = zin.getNextEntry
    e0.getName should be ("file1.txt")
    val bytes0 = io.readInputStream[Task](Task.now(zin), 500, false).runLog.unsafeRun
    bytes0 should be (data.toList.head._2.runLog.unsafeRun)

    val e1 = zin.getNextEntry
    e1.getName should be ("file2.txt")
    val bytes1 = io.readInputStream[Task](Task.now(zin), 500, false).runLog.unsafeRun
    bytes1 should be (data.toList.apply(1)._2.runLog.unsafeRun)

    zin.getNextEntry should be (null)
    zin.close
  }
}
