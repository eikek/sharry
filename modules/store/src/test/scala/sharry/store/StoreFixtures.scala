package sharry.store

import java.io.InputStream
import java.time.Instant
import java.net.URL
import fs2.Stream
import cats.effect.IO
import doobie._
import sharry.common._
import sharry.common.file._

trait StoreFixtures {
  private def evo(db: String) = evolution(evolution.H2, db)

  def now = Instant.now

  def tx(db: String): Transactor[IO] =
    Transactor.fromDriverManager[IO](
      "org.h2.Driver", s"jdbc:h2:$db", "sa", ""
    )

  def newDb(xa: Transactor[IO], db: String): IO[Unit] = {
    (Stream.eval(evo(db).dropDatabase(xa)) ++ Stream.eval(evo(db).runChanges(xa))).compile.drain
  }

  def resource(name: String): IO[InputStream] =
    IO(Option(getClass.getResourceAsStream(name)).get)

  def resourceUrl(name: String): URL =
    Option(getClass.getResource(name)).get

  def newDb(code: Transactor[IO] => Any): Unit = {
    val name = rng.Gen.alphaNum(4, 12).generate()
    val db = file("target")/name
    val xa = tx(db.absolute.toString)
    try {
      newDb(xa, name).unsafeRunSync
      code(xa)
    } finally {
      db.parent.
        list.
        filter(_.name startsWith name).
        foreach(_.delete.unsafeRunSync)
    }
  }
}
