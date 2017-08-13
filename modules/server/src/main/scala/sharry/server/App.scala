package sharry.server

import java.nio.file.Path
import java.nio.channels.AsynchronousChannelGroup
import com.typesafe.config.{ConfigFactory, ConfigRenderOptions}

import sharry.docs.route
import sharry.docs.md.ManualContext
import sharry.store.account._
import sharry.store.binary._
import sharry.store.upload._
import sharry.webapp.config.RemoteConfig
import sharry.server.authc._
import sharry.webapp.route.webjar
import sharry.webapp.config._
import sharry.server.routes.{account, login, upload, download, alias, mail}

/** Instantiate the app from a given configuration */
final class App(val cfg: config.Config)(implicit ACG: AsynchronousChannelGroup, S: fs2.Strategy, SCH: fs2.Scheduler) {
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
      , uploadConfig.maxValidity.toString
      , App.makeProjectString
      , routes.authz.aliasHeaderName
      , cfg.webmailConfig.enable
      , cfg.webConfig.highlightjsTheme
  )

  val notifier: notification.Notifier = notification.scheduleNotify(
    cfg.smtpSetting, cfg.webConfig, cfg.webmailConfig, uploadStore, accountStore)_


  def endpoints = {
    val opts = ConfigRenderOptions.defaults().setOriginComments(false).setJson(false)
    routes.syntax.choice2(
      webjar.endpoint(remoteConfig)
        , route.manual(paths.manual.matcher, ManualContext(App.makeVersion, BuildInfo.version, ConfigFactory.defaultReference().getConfig("sharry").root().render(opts)))
        , login.endpoint(auth, cfg.webConfig, cfg.authConfig)
        , account.endpoint(auth, cfg.authConfig, accountStore, cfg.webConfig)
        , upload.endpoint(cfg.authConfig, uploadConfig, uploadStore, notifier)
        , download.endpoint(cfg.authConfig, cfg.webConfig, uploadStore)
        , alias.endpoint(cfg.authConfig, uploadConfig, uploadStore)
        , mail.endpoint(cfg.authConfig, cfg.smtpSetting, cfg.webmailConfig)
    )
  }

  def setupLogging(logFile: Path): Unit = {
    import org.slf4j.LoggerFactory
    import ch.qos.logback.classic.LoggerContext
    import ch.qos.logback.classic.joran.JoranConfigurator
    import ch.qos.logback.core.util.StatusPrinter
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

object App {
  def makeVersion: String = {
    val v =
      BuildInfo.version +
      BuildInfo.gitDescribedVersion.map(c => s" ($c)").getOrElse("")

    if (BuildInfo.gitUncommittedChanges) v + " [dirty workingdir]" else v
  }

  def makeProjectString: String = {
    s"Sharry ${makeVersion}"
  }
}
