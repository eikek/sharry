package sharry.store.migrate

import cats.effect.Sync

import sharry.store.JdbcConfig

import org.flywaydb.core.Flyway
import org.flywaydb.core.api.output.MigrateResult
import org.log4s._

object FlywayMigrate {
  private[this] val logger = getLogger

  def run[F[_]: Sync](jdbc: JdbcConfig): F[MigrateResult] =
    Sync[F].delay {
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
      .baselineOnMigrate(true)
      .baselineVersion("0")
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
      case Some("h2") =>
        List(s"classpath:db/migration/postgresql", "classpath:db/migration/h2")
      case Some(dbtype) =>
        List(s"classpath:db/migration/$dbtype")
      case None =>
        logger.warn(s"Cannot read database name from jdbc url: ${jdbc.url}. Go with H2")
        List(s"classpath:db/migration/postgresql", "classpath:db/migration/h2")
    }

}
