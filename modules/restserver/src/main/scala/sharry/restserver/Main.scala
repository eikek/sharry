package sharry.restserver

import cats.effect._
import cats.implicits._

import scala.concurrent.ExecutionContext
import java.util.concurrent.Executors
import java.nio.file.{Files, Paths}

import org.log4s._
import sharry.common._
import sharry.store.migrate.MigrateFrom06

object Main extends IOApp {
  private[this] val logger = getLogger

  val blockingEc: ExecutionContext = ExecutionContext.fromExecutor(
    Executors.newCachedThreadPool(ThreadFactories.ofName("sharry-restserver-blocking"))
  )
  val blocker = Blocker.liftExecutionContext(blockingEc)
  val connectEC: ExecutionContext = ExecutionContext.fromExecutorService(
    Executors.newFixedThreadPool(5, ThreadFactories.ofName("sharry-dbconnect"))
  )

  def run(args: List[String]) = {
    args match {
      case file :: Nil =>
        val path = Paths.get(file).toAbsolutePath.normalize
        logger.info(s"Using given config file: $path")
        System.setProperty("config.file", file)
      case _ =>
        Option(System.getProperty("config.file")) match {
          case Some(f) if f.nonEmpty =>
            val path = Paths.get(f).toAbsolutePath.normalize
            if (!Files.exists(path)) {
              logger.info(s"Not using config file '$f' because it doesn't exist")
              System.clearProperty("config.file")
            } else {
              logger.info(s"Using config file from system properties: $f")
            }
          case _ =>
        }
    }

    val cfg = ConfigFile.loadConfig
    val banner = Banner(
      BuildInfo.version,
      BuildInfo.gitHeadCommit,
      cfg.backend.jdbc.url,
      Option(System.getProperty("config.file")),
      cfg.baseUrl
    )
    logger.info(s"\n${banner.render("***>")}")
    if ("true" == System.getProperty("sharry.migrate-old-dbschema")) {
      MigrateFrom06[IO](cfg.backend.jdbc, connectEC, blocker)
        .use(mig => mig.migrate)
        .as(ExitCode.Success)
    } else {
      RestServer
        .stream[IO](cfg, ExecutionContext.global, connectEC, blocker)
        .compile
        .drain
        .as(ExitCode.Success)
    }
  }
}
