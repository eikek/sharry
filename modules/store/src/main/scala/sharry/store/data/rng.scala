package sharry.store.data

import java.security.SecureRandom
import cats._
import cats.data.State
import cats.implicits._
import scodec.bits.ByteVector

/** Taken from the book “Functional Programming In Scala”, chapter
  * 5. The rng is a LCG as described here:
  * https://en.wikipedia.org/wiki/Linear_congruential_generator and
  * the values are taken from GCC (as stated at the wikipedia page).*/
object rng {

  trait Rng {
    def nextLong: (Rng, Long)
  }

  object Rng {
    private val secureRandom = new SecureRandom()
    def apply(seed: Long = secureRandom.nextLong): Rng = new Rng {
      def nextLong: (Rng, Long) = {
        val newSeed = (seed * 1103515245L + 12345) % Int.MaxValue
        val nextRng = apply(newSeed)
        (nextRng, newSeed)
      }
    }
  }

  type Gen[A] = State[Rng, A]

  object Gen {
    def apply[A](f: Rng => (Rng, A)): Gen[A] = State(f)
    def apply(): Gen[Long] = Gen(_.nextLong)

    def unit[A](a: A): Gen[A] = apply(rng => (rng, a))

    def int = apply().map(_.##)

    def positiveInt: Gen[Int] =
      int.map(i => if (i < 0) -(i + 1) else i)

    def bool: Gen[Boolean] = int.map(_ % 2 == 0)

    def boundedInt(min: Int, max: Int): Gen[Int] =
      positiveInt.map(n => n % (max - min) + min)

    def chars(alphabet: IndexedSeq[Char], min: Int, max: Int): Gen[List[Char]] =
      for {
        len  <- boundedInt(min, max)
        ints <- Monad[Gen].sequence(List.fill(len)(boundedInt(0, alphabet.length)))
      } yield ints.map(alphabet)

    def string(alphabet: IndexedSeq[Char], min: Int, max: Int): Gen[String] =
      chars(alphabet, min, max).map(_.mkString)

    def alphaNum(min: Int, max: Int): Gen[String] =
      string(('a' to 'z') ++ ('A' to 'Z') ++ ('0' to '9'), min, max)

    def ident(min: Int, max: Int): Gen[String] = {
      require(min > 1, "idents must be >1 chars")
      val chars = ('a' to 'z') ++ ('A' to 'Z') ++ ('0' to '9') ++ "_-"
      for {
        first <- alphaNum(1,2)
        rest <- string(chars, min-1, max-1)
      } yield first + rest
    }

    def bytes(len: Int): Gen[ByteVector] =
      string("1234567890abcdef", len * 2, len * 2 + 1).map(s => ByteVector.fromValidHex(s))

 }

  implicit class GenOps[A](val gen: Gen[A]) extends AnyVal {
    def generate(rng: Rng = Rng()): A = gen.runA(rng).value
  }
}
