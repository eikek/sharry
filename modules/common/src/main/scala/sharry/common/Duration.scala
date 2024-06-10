package sharry.common

import java.time.Duration as JDur
import java.util.concurrent.TimeUnit

import scala.concurrent.duration.{Duration as SDur, FiniteDuration}

import cats.effect.Sync
import cats.implicits.*

import io.circe.Decoder
import io.circe.Encoder

final class Duration(val nanos: Long) extends AnyVal {

  def <=(other: Duration): Boolean =
    nanos <= other.nanos

  def >=(other: Duration): Boolean =
    nanos >= other.nanos

  def +(other: Duration): Duration =
    new Duration(nanos + other.nanos)

  def millis: Long = nanos / 1000000

  def seconds: Long = millis / 1000

  def minutes: Long = seconds / 60

  def toScala: FiniteDuration =
    FiniteDuration(nanos, TimeUnit.NANOSECONDS)

  def toJava: JDur =
    JDur.ofNanos(nanos)

  def formatExact: String =
    s"$millis ms"

  def formatHuman: String = {
    val factors =
      List(
        (1000000, "millis"),
        (1000, "seconds"),
        (60, "minutes"),
        (60, "hours"),
        (24, "days")
      )

    val (value, unit) = factors.foldLeft((nanos.toDouble, "nanos")) {
      case ((r, runit), (fac, funit)) =>
        if (r < fac) (r, runit)
        else (r / fac.toDouble, funit)
    }
    s"$value $unit"
  }

  override def toString(): String =
    formatHuman
}

object Duration {

  val zero: Duration = new Duration(0L)

  def fromString(s: String): Either[String, Duration] =
    s.toLongOption match
      case Some(n) => Right(millis(n))
      case None =>
        try Right(apply(scala.concurrent.duration.Duration(s)))
        catch case ex: Throwable => Left(s"Invalid duration '$s': ${ex.getMessage}")

  def apply(d: SDur): Duration =
    new Duration(d.toNanos)

  def apply(d: JDur): Duration =
    new Duration(d.toNanos)

  def seconds(n: Long): Duration =
    apply(JDur.ofSeconds(n))

  def millis(n: Long): Duration =
    apply(JDur.ofMillis(n))

  def minutes(n: Long): Duration =
    apply(JDur.ofMinutes(n))

  def hours(n: Long): Duration =
    apply(JDur.ofHours(n))

  def days(n: Long): Duration =
    apply(JDur.ofDays(n))

  def nanos(n: Long): Duration =
    new Duration(n)

  def stopTime[F[_]: Sync]: F[F[Duration]] =
    for {
      now <- Timestamp.current[F]
      end = Timestamp.current[F]
    } yield end.map(e => Duration.millis(e.toMillis - now.toMillis))

  implicit def jsonDecoder: Decoder[Duration] =
    Decoder.decodeLong.map(Duration.millis)

  implicit def jsonEncoder: Encoder[Duration] =
    Encoder.encodeLong.contramap(_.millis)

}
