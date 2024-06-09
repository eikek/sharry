package sharry.common.util

import cats.effect.*

import scodec.bits.ByteVector

trait Random[F[_]] {
  def string(len: Int): F[String]
  def string: F[String] = string(8)
}

object Random {
  def apply[F[_]: Sync] =
    new Random[F] {
      def string(len: Int) = Sync[F].delay {
        val buf = Array.ofDim[Byte](len)
        new scala.util.Random().nextBytes(buf)
        ByteVector.view(buf).toBase58
      }
    }
}
