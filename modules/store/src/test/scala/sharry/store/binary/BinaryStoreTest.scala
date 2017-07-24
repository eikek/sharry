package sharry.store.binary

import java.util.concurrent.CountDownLatch
import scala.concurrent.{Await, Future}
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global
import org.scalatest._
import doobie.imports._
import sharry.common.sizes._
import sharry.common._
import sharry.store._
import sharry.store.data._
import sharry.store.range._
import sharry.store.mimedetect._

class BinaryStoreTest extends FlatSpec with Matchers with StoreFixtures {

  "save" should "save a file" in newDb { xa =>
    val store = new SqlBinaryStore(xa)
    val chunkSize = 16.kbytes
    val out = store.save(streams.readIs(resource("/files/file.pdf"), chunkSize), chunkSize, MimeInfo.none, now).runLast.unsafeRun.get
    out match {
      case Created(m) =>
        m.id should be ("8fabb506346fc4b10e0e10f33ec0fa819038d701224ca63cbee7620c38b4736f")
        m.chunks should be (4)
        m.length should be (65404.bytes)
      case _ =>
        sys.error(s"wrong outcome: $out")
    }
    val key = out.result

    val chunks = store.getChunks(key.id).runLog.unsafeRun
    chunks should have length (key.chunks.toLong)
    chunks.foreach(_.fileId should be (key.id))
    chunks.init.foreach(_.chunkLength should be (chunkSize))
    chunks.last.chunkLength should be (16252.bytes)
    chunks.foldLeft(Size.zero)(_ + _.chunkLength) should be (65404.bytes)
    sql"""SELECT count(*) FROM FileChunk""".query[Int].unique.transact(xa).unsafeRun should be (chunks.length)
  }

  it should "handle existing files" in newDb { xa =>
    val store = new SqlBinaryStore(xa)
    val chunkSize = 16.kbytes
    val out = store.save(streams.readIs(resource("/files/file.pdf"), chunkSize), chunkSize, MimeInfo.none, now).runLast.unsafeRun.get
    out match {
      case Created(m) =>
        m.id should be ("8fabb506346fc4b10e0e10f33ec0fa819038d701224ca63cbee7620c38b4736f")
        m.chunks should be (4)
        m.length should be (65404.bytes)
      case _ =>
        sys.error(s"wrong outcome: $out")
    }

    val out2 = store.save(streams.readIs(resource("/files/file.pdf"), chunkSize), chunkSize, MimeInfo.none, now).runLast.unsafeRun.get
    out2 should be (Unmodified(out.result))
    sql"""SELECT count(*) FROM FileChunk""".query[Int].unique.transact(xa).unsafeRun should be (out.result.chunks)
  }

  it should "save concurrently same file" in newDb { xa =>
    val store = new SqlBinaryStore(xa)
    val chunkSize = 32.kbytes
    val peng = new CountDownLatch(1)
    val f0 = Future {
      peng.await()
      store.save(streams.readIs(resource("/files/file.pdf"), chunkSize), chunkSize, MimeInfo.none, now).runLast.unsafeRun.get
    }
    val f1 = Future {
      peng.await()
      store.save(streams.readIs(resource("/files/file.pdf"), chunkSize), chunkSize, MimeInfo.none, now).runLast.unsafeRun.get
    }
    peng.countDown()
    val o0 = Await.result(f0, 5.seconds)
    val o1 = Await.result(f1, 5.seconds)
    o0 should (be ('unmodified) or be ('created))
    o1 should (be ('unmodified) or be ('created))
    o0.isCreated should not be (o1.isCreated)
    o0.isUnmodified should not be (o1.isUnmodified)
  }

  "get" should "be loadable in chunks" in newDb { xa =>
    import RangeSpec.bytes
    val store = new SqlBinaryStore(xa)
    val chunkSize = 16.kbytes
    val Created(key) = store.save(streams.readIs(resource("/files/file.pdf"), chunkSize), chunkSize, MimeInfo.none, now).runLast.unsafeRun.get

    def getBase64(r: RangeSpec) =
      store.get(key.id).
        through(streams.optionToEmpty).
        through(store.fetchData2(r)).
        through(streams.toBase64String).
        runLast.
        unsafeRun

    getBase64(bytes(None, Some(80))) should be (
      Some("JVBERi0xLjUKJdDUxdgKMTAgMCBvYmoKPDwKL0xlbmd0aCAyNjMgICAgICAgCi9GaWx0ZXIgL0ZsYXRlRGVjb2RlCj4+CnN0cmVhbQp42m0=")
    )
    getBase64(bytes(Some(3500), Some(80))) should be (
      Some("3cNffssNBJtMRzfLcgH1ZcU2oG/jomzHp36AIrrZj/sKimkjyHQXTeauUbnWnsIJ5Ub8zb59xvW6fLSnkqaOlgJXKXyVD0gJYFUFBvRJYvQ=")
    )
    getBase64(bytes(Some(16344), Some(80))) should be (
      Some("uL7wCy2XxucsUna47LombVa37iCz2RwEaBu2vq//4bxtPpRUDXfyww3E0LtPykG8MCG5SoO7kFmGJYLATDY8pi96l+qdvEFJvlJPRPfonwg=")
    )
  }

  "exists" should "tell whether bytes exist" in newDb { xa =>
    val store = new SqlBinaryStore(xa)
    val chunkSize = 16.kbytes
    val Created(key) = store.save(streams.readIs(resource("/files/file.pdf"), chunkSize), chunkSize, MimeInfo.none, now).runLast.unsafeRun.get
    store.exists(key.id).runLast.unsafeRun.get should be (true)
    store.exists("abc").runLast.unsafeRun.get should be (false)
  }

  "delete" should "delete all chunks" in newDb { xa =>
    val store = new SqlBinaryStore(xa)
    val chunkSize = 16.kbytes
    val Created(key) = store.save(streams.readIs(resource("/files/file.pdf"), chunkSize), chunkSize, MimeInfo.none, now).runLast.unsafeRun.get

    store.delete(key.id).runLast.unsafeRun.get should be (true)
    store.exists(key.id).runLast.unsafeRun.get should be (false)
    sql"""SELECT count(*) from FileChunk""".query[Int].unique.transact(xa).unsafeRun should be (0)
  }
}
