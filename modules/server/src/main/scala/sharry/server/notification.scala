package sharry.server

import java.time.{Duration, Instant}
import fs2.{time, Strategy, Scheduler, Stream, Task}
import scala.concurrent.duration.{MILLISECONDS, FiniteDuration}
import yamusca.imports._

import sharry.store.upload.UploadStore
import sharry.store.account.AccountStore
import sharry.store.data.{Alias, Upload}
import sharry.common.streams
import sharry.server.config._
import sharry.server.email._

object notification {

  type Notifier = (String, Alias, Duration) => Stream[Task,Unit]

  def scheduleNotify(smtp: GetSetting
    , webCfg: WebConfig
    , mailCfg: WebmailConfig
    , store: UploadStore
    , accounts: AccountStore)
    (implicit S: Strategy, SCH: Scheduler): Notifier = { (id, alias, time) =>

    val send = client.send_(smtp)_
    val workTask = findRecipient(id, alias, store, accounts).
      evalMap(makeNotifyMail(webCfg, mailCfg)).
      flatMap(send).
      run

    checkAliasAccess(id, alias, time, store).flatMap {
      case true =>
        findRecipient(id, alias, store, accounts).
          evalMap(_ => Task.start(schedule(workTask, time))).
          map(_ => ())

      case false =>
        Stream.emit(())
    }
  }

  private def schedule[A](task: Task[A], delay: Duration)
    (implicit S: Strategy, SCH: Scheduler): Task[Unit] = {

    val fd = FiniteDuration(delay.toMillis, MILLISECONDS)
    time.sleep[Task](fd).evalMap(_ => task).run
  }

  def checkAliasAccess(id: String
    , alias: Alias
    , time: Duration
    , store: UploadStore) = {
    // a request authorized by an alias id to delete an upload is only
    // valid if issued less than X minutes after uploading and it was
    // initially uploaded by this alias
    val now = Instant.now
    store.getUpload(id, alias.login).
      map({ info =>
        info.upload.alias == Some(alias.id) &&
        info.upload.created.plus(time).isAfter(now)
      })
  }


  def makeNotifyMail(webCfg: WebConfig, mailCfg: WebmailConfig)
    (data: (Upload, String)): Task[Mail] = {
    val (upload, recipient) = data
    val templ = mailCfg.notifyTemplates(mailCfg.defaultLanguage)
    val ctx = Context(
      "username" -> Value.of(upload.login)
        , "uploadId" -> Value.of(upload.id)
        , "alias" -> Value.of(upload.aliasName)
        , "aliasId" -> Value.of(upload.alias)
        , "uploadUrl" -> Value.of(webCfg.baseurl + "#uid=" + upload.id)
    )
    val text = mustache.render(templ)(ctx)
    val (subject, body) = text.span(_ != '\n')
    Mail(to = recipient
      , subject = subject
      , text = body)
  }

  def findRecipient(uploadId: String
    , alias: Alias
    , store: UploadStore
    , accounts: AccountStore): Stream[Task,(Upload,String)] =
    for {
      info <- {
        store.getUpload(uploadId, alias.login).
          filter(_.upload.alias == Some(alias.id))
      }
      receiver <- {
        accounts.getAccount(alias.login).
          filter(_.enabled).
          map(_.email).
          through(streams.optionToEmpty)
      }
    } yield (info.upload, receiver)
}
