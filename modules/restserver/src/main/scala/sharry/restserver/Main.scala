package sharry.restserver

import java.nio.file.{Files, Paths}

import cats.effect._

import sharry.common._
import sharry.logging.impl.ScribeConfigure
import sharry.restserver.config.ConfigFile

object Main extends IOApp {
  private[this] val logger = sharry.logging.getLogger[IO]

  val connectEC =
    ThreadFactories.fixed[IO](5, ThreadFactories.ofName("sharry-dbconnect"))

  def run(args: List[String]): IO[ExitCode] =
    for {
      _ <- IO {
        args match {
          case file :: Nil =>
            val path = Paths.get(file).toAbsolutePath.normalize
            logger.asUnsafe.info(s"Using given config file: $path")
            System.setProperty("config.file", file)
          case _ =>
            Option(System.getProperty("config.file")) match {
              case Some(f) if f.nonEmpty =>
                val path = Paths.get(f).toAbsolutePath.normalize
                if (!Files.exists(path)) {
                  logger.asUnsafe.info(
                    s"Not using config file '$f' because it doesn't exist"
                  )
                  System.clearProperty("config.file")
                } else
                  logger.asUnsafe.info(s"Using config file from system properties: $f")
              case _ =>
            }
        }
      }

      cfg = ConfigFile.loadConfig

      _ <- ScribeConfigure.configure[IO](cfg.logging)

      banner = Banner(
        BuildInfo.version,
        BuildInfo.gitHeadCommit,
        cfg.backend.jdbc.url,
        Option(System.getProperty("config.file")),
        cfg.baseUrl,
        cfg.backend.files.defaultStoreConfig.toString
      )

      _ <- logger.info(s"\n${banner.render("***>")}")
      _ <- logger.info(s"\n${cfg.backend.files.stores}\n")

      pools = connectEC.map(Pools.apply)
      _ <-
        if (EnvMode.current.isDev) {
          logger.warn(">>>>>   Sharry is running in DEV mode!   <<<<<")
        } else IO(())
      _ <- logger.info(s"Alias-Member feature enabled: ${cfg.aliasMemberEnabled}")

      exit <-
        pools.use { p =>
          RestServer
            .stream[IO](cfg, p)
            .compile
            .drain
            .as(ExitCode.Success)
        }
    } yield exit
}
