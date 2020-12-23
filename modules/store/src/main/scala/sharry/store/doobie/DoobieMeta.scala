package sharry.store.doobie

import java.time.format.DateTimeFormatter
import java.time.{Instant, LocalDate}

import doobie._
import doobie.util.log.Success
import io.circe.{Decoder, Encoder}
import sharry.common._
import sharry.common.syntax.all._
import bitpeace.Mimetype

trait DoobieMeta {

  implicit val sqlLogging = LogHandler({
    case e @ Success(_, _, _, _) =>
      DoobieMeta.logger.trace("SQL " + e)
    case e =>
      DoobieMeta.logger.error(s"SQL Failure: $e")
  })

  def jsonMeta[A](implicit d: Decoder[A], e: Encoder[A]): Meta[A] =
    Meta[String].imap(str => str.parseJsonAs[A].fold(ex => throw ex, identity))(a =>
      e.apply(a).noSpaces
    )

  implicit val metaUserState: Meta[AccountState] =
    Meta[String].timap(AccountState.unsafe)(AccountState.asString)

  implicit val metaAccountSource: Meta[AccountSource] =
    Meta[String].timap(AccountSource.unsafe)(_.name)

  implicit val metaPassword: Meta[Password] =
    Meta[String].timap(Password(_))(_.pass)

  implicit val metaIdent: Meta[Ident] =
    Meta[String].timap(Ident.unsafe)(_.id)

  implicit val ciIdentMeta: Meta[CIIdent] =
    metaIdent.timap(CIIdent.apply)(_.value)

  implicit val metaTimestamp: Meta[Timestamp] =
    Meta[String].timap(s => Timestamp(Instant.parse(s)))(_.value.toString)

  implicit val metaLocalDate: Meta[LocalDate] =
    Meta[String].timap(str => LocalDate.parse(str))(_.format(DateTimeFormatter.ISO_DATE))

  implicit val metaDuration: Meta[Duration] =
    Meta[Long].timap(n => Duration.seconds(n))(_.seconds)

  implicit val metaByteSize: Meta[ByteSize] =
    Meta[Long].timap(n => ByteSize(n))(_.bytes)

  implicit val metaMimetype: Meta[Mimetype] =
    Meta[String].imap(Mimetype.parse(_).fold(ex => throw ex, identity))(_.asString)

}

object DoobieMeta extends DoobieMeta {
  import org.log4s._
  private val logger = getLogger
}
