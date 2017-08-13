package sharry.store

import java.io.InputStream
import java.time.Instant
import java.net.URL
import fs2.{Stream, Task}
import fs2.interop.cats._
import doobie.imports._
import sharry.common._
import sharry.common.file._

trait StoreFixtures {
  private def evo(db: String) = evolution(evolution.H2, db)

  def now = Instant.now

  def tx(db: String): Transactor[Task] =
    DriverManagerTransactor[Task]("org.h2.Driver", s"jdbc:h2:$db", "sa", "")

  def newDb(xa: Transactor[Task], db: String): Task[Unit] = {
    (Stream.eval(evo(db).dropDatabase(xa)) ++ Stream.eval(evo(db).runChanges(xa))).run
  }

  def resource(name: String): Task[InputStream] =
    Task.delay(Option(getClass.getResourceAsStream(name)).get)

  def resourceUrl(name: String): URL =
    Option(getClass.getResource(name)).get

  def newDb(code: Transactor[Task] => Any): Unit = {
    val name = rng.Gen.alphaNum(4, 12).generate()
    val db = file("target")/name
    val xa = tx(db.absolute.toString)
    try {
      newDb(xa, name).unsafeRun
      code(xa)
    } finally {
      db.parent.
        list.
        filter(_.name startsWith name).
        foreach(_.delete.unsafeRun)
    }
  }
}
