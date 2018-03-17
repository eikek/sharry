package sharry.common

import java.nio.file.Path
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import scodec.bits.ByteVector
import fs2.Pipe
import cats.effect.IO

import file._
import sizes._

object sha {
  private def create: MessageDigest =
    MessageDigest.getInstance("SHA-256")

  private def hex(bytes: Array[Byte]): String =
    ByteVector.view(bytes).toHex

  def apply(s: String): String = {
    val digest = create
    digest.update(s.getBytes(StandardCharsets.UTF_8))
    hex(digest.digest())
  }

  def apply(path: Path): IO[String] =
    path.readAll(64.kbytes)
      .through(makeShaArray)
      .compile.toVector
      .map(_.head)

  def apply(bytes: ByteVector): String = {
    val digest = create
    digest.update(bytes.toArray)
    hex(digest.digest())
  }

  def makeShaBV[F[_]]: Pipe[F, ByteVector, String] =
    _.fold(sha.newBuilder)(_ update _).map(_.get)

  def makeShaArray[F[_]]: Pipe[F, Byte, String] =
    _.chunks.fold(sha.newBuilder)(_ update _.toArray).map(_.get)

  def newBuilder = new ShaBuilder
  final class ShaBuilder {
    private val digest = create
    def update(data: ByteVector): ShaBuilder =
      update(data.toArray)

    def update(data: Array[Byte]): ShaBuilder = {
      digest.update(data)
      this
    }

    def get: String = hex(digest.digest())
  }
}
