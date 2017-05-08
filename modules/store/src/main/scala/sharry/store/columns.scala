package sharry.store

import java.time.{Duration, Instant}
import java.time.temporal._
import com.typesafe.scalalogging.Logger
import scodec.bits.ByteVector
import sharry.store.data.mime.MimeType
import sharry.store.data.sizes._
import doobie.imports._
import doobie.util.log.{Success, ProcessingFailure, ExecFailure}

object columns {

  implicit val bvMeta: Meta[ByteVector] =
    Meta[Array[Byte]].nxmap(
      ar => ByteVector(ar),
      bv => bv.toArray
    )

  implicit val mimetypeMeta: Meta[MimeType] =
    Meta[String].nxmap(MimeType.parse(_).get, _.asString)

  implicit val instantMeta: Meta[Instant] =
    Meta[String].nxmap(Instant.parse, _.truncatedTo(ChronoUnit.SECONDS).toString)

  implicit val durationMeta: Meta[Duration] =
    Meta[String].nxmap(Duration.parse, _.toString)

  implicit val sizeMeta: Atom[Size] =
    Atom[Long].imap[Size](n => Bytes(n))(_.toBytes)

  implicit class FragmentOps(sqlf: Fragment) {
    def offset(n: Option[Int]): Fragment =
      n.map(offset).getOrElse(sqlf)

    def offset(n: Int): Fragment =
      sqlf ++ sql""" OFFSET $n"""

    def limit(n: Option[Int]): Fragment =
      n.map(limit).getOrElse(sqlf)

    def limit(n: Int): Fragment =
      sqlf ++ sql""" LIMIT $n"""
  }

  def logSql(logger: Logger): LogHandler = LogHandler {
    case Success(s, a, e1, e2) =>
      logger.trace(s"""Successful Statement Execution:
            |
            |  ${s.lines.dropWhile(_.trim.isEmpty).mkString("\n  ")}
            |
            | arguments = [${a.mkString(", ")}]
            |   elapsed = ${e1.toMillis} ms exec + ${e2.toMillis} ms processing (${(e1 + e2).toMillis} ms total)
          """.stripMargin)

    case ProcessingFailure(s, a, e1, e2, t) =>
      logger.error(s"""Failed Resultset Processing:
            |
            |  ${s.lines.dropWhile(_.trim.isEmpty).mkString("\n  ")}
            |
            | arguments = [${a.mkString(", ")}]
            |   elapsed = ${e1.toMillis} ms exec + ${e2.toMillis} ms processing (failed) (${(e1 + e2).toMillis} ms total)
            |   failure = ${t.getMessage}
          """.stripMargin)

    case ExecFailure(s, a, e1, t) =>
      logger.error(s"""Failed Statement Execution:
            |
            |  ${s.lines.dropWhile(_.trim.isEmpty).mkString("\n  ")}
            |
            | arguments = [${a.mkString(", ")}]
            |   elapsed = ${e1.toMillis} ms exec (failed)
            |   failure = ${t.getMessage}
          """.stripMargin)
  }
}
