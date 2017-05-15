package sharry.common

import java.util.Base64
import scodec.bits.ByteVector

/** Wrapper around java8 base64 */
object base64 {

  final class Codec(enc: Base64.Encoder, dec: Base64.Decoder) {
    def decode(s: String): ByteVector = ByteVector.view(dec.decode(s))
    def decode(b: ByteVector): ByteVector = ByteVector.view(dec.decode(b.toByteBuffer))
    def decode(b: Array[Byte]): Array[Byte] = dec.decode(b)

    def encodeToString(b: ByteVector): String = enc.encodeToString(b.toArray)
    def encode(b: ByteVector): ByteVector = ByteVector.view(enc.encode(b.toByteBuffer))
    def encodeToString(b: Array[Byte]): String = enc.encodeToString(b)
    def encode(b: Array[Byte]): Array[Byte] = enc.encode(b)
  }

  val basic = new Codec(Base64.getEncoder, Base64.getDecoder)
  val mime = new Codec(Base64.getMimeEncoder, Base64.getMimeDecoder)
  val url = new Codec(Base64.getUrlEncoder, Base64.getUrlDecoder)
}
