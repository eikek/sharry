package sharry.store.data

import java.nio.file.{Files, Paths}
import org.scalatest._
import fs2.{io, Strategy, Stream, Task}

class ZipTest extends FlatSpec with Matchers {
  implicit val S = Strategy.fromCachedDaemonPool("test")

  "entries" should "list files" in {
    val dir = Paths.get("/home/eike/workspace/projects/sharry/modules/webapp/src")
    val out = Paths.get("/home/eike/workspace/projects/sharry/test.zip")
    Files.deleteIfExists(out)

    zip.zipDir[Task](dir, 8192).
      through(io.file.writeAll(out)).
      run.unsafeRun


  }
}
