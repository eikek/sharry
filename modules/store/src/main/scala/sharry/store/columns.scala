package sharry.store

import java.time.Instant
import java.time.temporal._
import org.log4s._
import scodec.bits.ByteVector
import sharry.common.mime.MimeType
import sharry.common.sizes._
import sharry.common.duration._
import doobie.imports._
import doobie.util.log.{Success, ProcessingFailure, ExecFailure}

object columns {

  implicit val bvMeta: Meta[ByteVector] =
    Meta[Array[Byte]].xmap(
      ar => ByteVector(ar),
      bv => bv.toArray
    )

  implicit val mimetypeMeta: Meta[MimeType] =
    Meta[String].xmap(MimeType.parse(_).get, _.asString)

  implicit val instantMeta: Meta[Instant] =
    Meta[String].xmap(Instant.parse, _.truncatedTo(ChronoUnit.SECONDS).toString)

  implicit val durationMeta: Meta[Duration] =
    Meta[String].xmap((java.time.Duration.parse _) andThen Duration.fromJava, _.asJava.toString)

  implicit val sizeMeta: Meta[Size] =
    Meta[Long].xmap[Size](n => Bytes(n), _.toBytes)

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
