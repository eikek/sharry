package sharry.common

import io.circe._

object sizes {

  sealed abstract class Size {
    def toBytes: Long
    def bytes: Int = toBytes.toInt
    def asString: String

    def + (other: Size): Size =
      Bytes(toBytes + other.toBytes)

    def > (other: Size): Boolean =
      toBytes > other.toBytes

    def >= (other: Size): Boolean =
      toBytes >= other.toBytes

    def < (other: Size): Boolean =
      toBytes < other.toBytes

    def <= (other: Size): Boolean =
      toBytes <= other.toBytes


    override def equals(o: Any): Boolean =
      o match {
        case sz: Size => Size.equals(this, sz)
        case _ => false
      }
  }

  object Size {
    val zero: Size = Bytes(0L)

    def equals(s1: Size, s2: Size): Boolean =
      s1.toBytes == s2.toBytes

    implicit val _sizeDec: Decoder[Size] = Decoder.decodeLong.map(b => Bytes(b))
    implicit val _sizeEnc: Encoder[Size] = Encoder.encodeLong.contramap[Size](_.toBytes)

    private[sizes] def format(d: Double) = "%.2f".formatLocal(java.util.Locale.ROOT, d)
  }

  case class Bytes(value: Long) extends Size {
    def toBytes = value
    def asString =
      if (value < 1024) s"${value}B"
      else KBytes(value / 1024.0).asString
  }

  case class KBytes(value: Double) extends Size {
    def toBytes = (value * 1024).toLong
    def asString =
      if (value < 1024) s"${Size.format(value)}K"
      else MBytes(value / 1024.0).asString
  }

  case class MBytes(value: Double) extends Size {
    def toBytes = (value * 1024 * 1024).toLong
    def asString =
      if (value < 1024) s"${Size.format(value)}M"
      else GBytes(value / 1024.0).asString
  }

  case class GBytes(value: Double) extends Size {
    def toBytes = (value * 1024 * 1024 * 1024).toLong
    def asString = s"${Size.format(value)}G"
  }

  implicit final class IntSizeOps(val n: Int) extends AnyVal {
    def gbytes: Size = GBytes(n.toDouble)
    def mbytes: Size = MBytes(n.toDouble)
    def kbytes: Size = KBytes(n.toDouble)
    def bytes: Size = Bytes(n.toLong)
  }
  implicit final class LongSizeOps(val n: Long) extends AnyVal {
    def gbytes: Size = GBytes(n.toDouble)
    def mbytes: Size = MBytes(n.toDouble)
    def kbytes: Size = KBytes(n.toDouble)
    def bytes: Size = Bytes(n)
  }
}
