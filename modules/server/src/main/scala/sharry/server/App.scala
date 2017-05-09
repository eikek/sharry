package sharry.server

import java.nio.file.Path
import java.nio.channels.AsynchronousChannelGroup
import spinoco.fs2.http.routing._

import sharry.store.account._
import sharry.store.binary._
import sharry.store.upload._
import sharry.webapp.config.RemoteConfig
import sharry.server.authc._
import sharry.webapp.route.webjar
import sharry.webapp.config._
import sharry.server.routes.{account, login, upload, download, alias}

/** Instantiate the app from a given configuration */
final class App(val cfg: config.Config)(implicit ACG: AsynchronousChannelGroup, S: fs2.Strategy) {
  if (cfg.logConfig.exists) {
    setupLogging(cfg.logConfig.config)
  }

  val jdbc = cfg.jdbc.transactor.unsafeRun

  val binaryStore: BinaryStore = new SqlBinaryStore(jdbc)
  val accountStore: AccountStore = new SqlAccountStore(jdbc)
  val uploadStore: UploadStore = new SqlUploadStore(jdbc, binaryStore)

  val auth = new Authenticate(accountStore, cfg.authConfig, ExternAuthc(cfg))

  val uploadConfig = cfg.uploadConfig

  val remoteConfig = RemoteConfig(
    paths.mounts.mapValues(_.path) + ("baseUrl" -> cfg.webConfig.baseurl)
      , cfg.webConfig.appName
      , cfg.authConfig.enable
      , cfg.authConfig.maxCookieLifetime.toMillis
      , uploadConfig.chunkSize.toBytes
      , uploadConfig.simultaneousUploads
      , uploadConfig.maxFiles
      , uploadConfig.maxFileSize.toBytes
      , makeProjectString
      , routes.authz.aliasHeaderName
  )


  def endpoints = {
    choice(
      webjar.endpoint(remoteConfig)
        , login.endpoint(auth, cfg.webConfig, cfg.authConfig)
        , account.endpoint(auth, cfg.authConfig, accountStore, cfg.webConfig)
        , upload.endpoint(cfg.authConfig, uploadStore)
        , download.endpoint(cfg.authConfig, cfg.webConfig, uploadStore)
        , alias.endpoint(cfg.authConfig, uploadStore)
        , routes.mail.endpoint(cfg.authConfig)
    )
  }

  def makeProjectString: String = {
    import BuildInfo._
    s"Sharry ${version}"
  }

  def setupLogging(logFile: Path): Unit = {
    import org.slf4j.LoggerFactory
    import ch.qos.logback.classic.LoggerContext
    import ch.qos.logback.classic.joran.JoranConfigurator
    import ch.qos.logback.core.util.StatusPrinter
    println(s">>>>>> using logback config file $logFile")
    val context = LoggerFactory.getILoggerFactory.asInstanceOf[LoggerContext]
    scala.util.Try {
      val config = new JoranConfigurator()
      config.setContext(context)
      context.reset()
      config.doConfigure(logFile.toString)
    }
    StatusPrinter.printInCaseOfErrorsOrWarnings(context)
  }
}
