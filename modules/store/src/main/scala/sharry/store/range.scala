package sharry.store

import cats.data.Ior
import cats.implicits._
import fs2.{Pipe, Stream, Task}
import scodec.bits.ByteVector
import sharry.common.sizes._
import sharry.common.streams

object range {
  type RangeSpec = Size => Option[Range]

  object RangeSpec {
    val none: RangeSpec = _ => Range.empty
    val all: RangeSpec = _ => Range.all

    /** Calculating Range given the chunksize */
    def bytes(offset: Option[Int], count: Option[Int]): RangeSpec = { chunkSz =>
      val chunkSize = chunkSz.bytes
      val left = offset.map { off =>
        (off / chunkSize, off % chunkSize)
      }
      // count = (chunkSize - dropL) + (chunkSize - dropR) + (chunkSize * (limit -2))
      //         first row             last row              intermediate rows
      // limit = ((count - (cs - dropL) - (cs -dropR)) / cs) + 2
      val right = count.map { len =>
        val rest = (offset.orEmpty + len) % chunkSize
        val dropR = if (rest == 0) 0 else chunkSize - rest
        val dropL = left.map(_._2).orEmpty
        val limit = ((len - (chunkSize - dropL) - (chunkSize - dropR)) / chunkSize) + 2
        (limit, dropR)
      }
        (left, right) match {
        case (Some(l), Some(r)) => Some(Range(Ior.both(l, r)))
        case (Some(l),       _) => Some(Range(Ior.left(l)))
        case (_,       Some(r)) => Some(Range(Ior.right(r)))
        case _ => None
      }
    }

    def firstChunks(n: Int): RangeSpec = { chunkSize =>
      require (n > 0)
      bytes(None, Some(n * chunkSize.bytes))(chunkSize)
    }

    val firstChunk: RangeSpec = firstChunks(1)

    def firstBytes(n: Int): RangeSpec = {
      require(n > 0)
      bytes(None, Some(n))
    }

    /** From a range like a-b in bytes. It may also be -b or a-. */
    def byteRange(value: Ior[Int, Int]): RangeSpec = {
      value match {
        case Ior.Left(a) =>
          bytes(Some(a), None)
        case Ior.Right(b) =>
          bytes(None, Some(b))
        case Ior.Both(a, b) =>
          bytes(Some(a), Some(b -a))
      }
    }

  }

  case class Range(range: Ior[(Int, Int), (Int, Int)]) {
    def offset: Option[Int] = range.left.map(_._1)
    def dropL: Option[Int] = range.left.map(_._2).filter(_ > 0)
    def limit: Option[Int] = range.right.map(_._1)
    def dropR: Option[Int] = range.right.map(_._2).filter(_ > 0)
    def isEmpty = limit.exists(_ == 0)

    def select(s: Stream[Task,ByteVector]): Stream[Task,Byte] = {
      s.through(Range.dropLeft(this)).
        through(Range.dropRight(this)).
        through(streams.unchunk)
    }
  }

  object Range {
    val empty: Option[Range] = Some(Range(Ior.right(0->0)))
    val all: Option[Range] = None

    def dropRight[F[_]](r: Range): Pipe[F,ByteVector,ByteVector] =
      r.dropR match {
        case None => identity
        case Some(n) =>
          _.through(streams.mapLast(_.dropRight(n.toLong)))
      }

    def dropLeft[F[_]](r: Range): Pipe[F,ByteVector,ByteVector] =
      r.dropL match {
        case None => identity
        case Some(n) =>
          _.zipWithIndex.map {
            case (bv, 0) => bv.drop(n.toLong)
            case (bv, _) => bv
          }
      }
  }
}
