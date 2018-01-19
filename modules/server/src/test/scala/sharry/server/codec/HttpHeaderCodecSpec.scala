package sharry.server.codec

import org.scalatest._
import scodec.bits.BitVector
import scodec.Attempt
import spinoco.protocol.http.header.GenericHeader

class HttpHeaderCodecSpec extends FlatSpec with Matchers {

  "header codec" should "not fail on empty cookie headers" in {
    HttpHeaderCodec.codec(2000).decodeValue(BitVector.view("Cookie:".getBytes)) should be (
      Attempt.successful(GenericHeader("cookie", ""))
    )

    HttpHeaderCodec.codec(2000).decodeValue(BitVector.view("Cookie:  ".getBytes)) should be (
      Attempt.successful(GenericHeader("cookie", ""))
    )
  }

  it should "not fail on spurous uri in referer header" in {

    HttpHeaderCodec.codec(2000).decodeValue(BitVector.view("Referer: android-app://com.google.android.gm".getBytes)) should be (
      Attempt.successful(GenericHeader("Referer", ""))
    )

  }
}
