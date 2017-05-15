package sharry.common

import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import scodec.bits.ByteVector

object sign {

  private def createNew = Mac.getInstance("HMACSHA256")

  def sign(key: Array[Byte], data: String): ByteVector = {
    val mac = createNew
    val seckey = new SecretKeySpec(key, mac.getAlgorithm)
    mac.init(seckey)
    mac.update(data.getBytes)
    val sig = mac.doFinal
    ByteVector.view(sig)
  }

  def sign(key: ByteVector, data: String): ByteVector =
    sign(key.toArray, data)

  def sign(key: String, data: String): ByteVector =
    sign(key.getBytes("UTF-8"), data)

}
