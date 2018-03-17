package sharry.server

import java.time.Instant
import fs2.{async, Scheduler, Stream}
import cats.effect.IO
import yamusca.implicits._
import scala.concurrent.ExecutionContext

import sharry.store.upload.UploadStore
import sharry.store.account.AccountStore
import sharry.store.data.Alias
import sharry.common.streams
import sharry.common.duration._
import sharry.common.data._
import sharry.server.config._
import sharry.server.email._

object notification {

  type Notifier = (String, Alias, Duration) => Stream[IO,Unit]

  def scheduleNotify(smtp: GetSetting
    , webCfg: WebConfig
    , mailCfg: WebmailConfig
    , store: UploadStore
    , accounts: AccountStore)
    (implicit SCH: Scheduler, EC: ExecutionContext): Notifier = { (id, alias, time) =>

    val send = client.send_(smtp)_
    val workTask = findRecipient(id, alias, store, accounts).
      evalMap(makeNotifyMail(webCfg, mailCfg)).
      flatMap(send).
      compile.drain

    checkAliasAccess(id, alias, time, store).flatMap {
      case true =>
        findRecipient(id, alias, store, accounts).
          evalMap(_ => async.start(schedule(workTask, time))).
          map(_ => ())

      case false =>
        Stream.emit(())
    }
  }

  private def schedule[A](task: IO[A], delay: Duration)
    (implicit SCH: Scheduler, EC: ExecutionContext): IO[Unit] = {

    SCH.sleep[IO](delay.asScala).evalMap(_ => task).compile.drain
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
        info.upload.created.plus(time.asJava).isAfter(now)
      })
  }


  def makeNotifyMail(webCfg: WebConfig, mailCfg: WebmailConfig)
    (data: (Upload, String)): IO[Mail] = {
    val (upload, recipient) = data
    val templ = mailCfg.notifyTemplates(mailCfg.defaultLanguage)
    val ctx = Map(
      "username" -> Some(upload.login)
        , "uploadId" -> Some(upload.id)
        , "alias" -> upload.aliasName
        , "aliasId" -> upload.alias
        , "uploadUrl" -> Some(webCfg.baseurl + "#uid=" + upload.id)
    )
    val text = ctx.render(templ)
    val (subject, body) = text.span(_ != '\n')
    Mail(to = recipient
      , subject = subject
      , text = body)
  }

  def findRecipient(uploadId: String
    , alias: Alias
    , store: UploadStore
    , accounts: AccountStore): Stream[IO,(Upload,String)] =
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
