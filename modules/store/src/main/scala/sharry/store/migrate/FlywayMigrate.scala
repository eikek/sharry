package sharry.store.migrate

import cats.effect.Sync
import sharry.store.JdbcConfig
import org.flywaydb.core.Flyway
import org.log4s._

object FlywayMigrate {
  private[this] val logger = getLogger

  def run[F[_]: Sync](jdbc: JdbcConfig): F[Int] = Sync[F].delay {
    logger.info("Running db migrations...")
    val fw = makeFlyway(jdbc)
    fw.repair()
    fw.migrate()
  }

  def makeFlyway(jdbc: JdbcConfig) = {
    val locations = findLocations(jdbc)
    logger.info(s"Using migration locations: $locations")
    Flyway
      .configure()
      .cleanDisabled(true)
      .dataSource(jdbc.url.asString, jdbc.user, jdbc.password)
      .locations(locations: _*)
      .load()
  }

  def baselineFlyway(jdbc: JdbcConfig): Flyway = {
    val locations = findLocations(jdbc)
    Flyway
      .configure()
      .dataSource(jdbc.url.asString, jdbc.user, jdbc.password)
      .baselineOnMigrate(true)
      .locations(locations: _*)
      .load()
  }

  def findLocations(jdbc: JdbcConfig) =
    jdbc.dbmsName match {
      case Some(dbtype) =>
        val name = if (dbtype == "h2") "postgresql" else dbtype
        List("classpath:db/migration/common", s"classpath:db/migration/${name}")
      case None =>
        logger.warn(s"Cannot read database name from jdbc url: ${jdbc.url}. Go with H2")
        List("classpath:db/migration/common", "classpath:db/h2")
    }

}
