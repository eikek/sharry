package sharry.common

import java.time.{Instant, LocalDate, ZoneId}

import cats.effect.Sync

import io.circe.{Decoder, Encoder}

case class Timestamp(value: Instant) {

  def toMillis: Long = value.toEpochMilli

  def toSeconds: Long = value.toEpochMilli / 1000L

  def minus(d: Duration): Timestamp =
    Timestamp(value.minusNanos(d.nanos))

  def plus(d: Duration): Timestamp =
    Timestamp(value.plusNanos(d.nanos))

  def minusHours(n: Long): Timestamp =
    Timestamp(value.minusSeconds(n * 60 * 60))

  def isBefore(other: Timestamp): Boolean =
    value.isBefore(other.value)

  def isAfter(other: Timestamp): Boolean =
    value.isAfter(other.value)

  def toDate: LocalDate =
    value.atZone(ZoneId.of("UTC")).toLocalDate

  def asString: String = value.toString
}

object Timestamp {

  val Epoch = Timestamp(Instant.EPOCH)

  def current[F[_]: Sync]: F[Timestamp] =
    Sync[F].delay(Timestamp(Instant.now))

  implicit val encodeTimestamp: Encoder[Timestamp] =
    BaseJsonCodecs.encodeInstantEpoch.contramap(_.value)

  implicit val decodeTimestamp: Decoder[Timestamp] =
    BaseJsonCodecs.decodeInstantEpoch.map(Timestamp(_))

}
