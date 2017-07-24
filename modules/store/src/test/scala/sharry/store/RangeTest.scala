package sharry.store

import cats.data.Ior
import org.scalatest._
import sharry.store.range._
import org.scalatest._
import sharry.common.sizes._


class RangeTest extends FlatSpec with Matchers {
  import RangeSpec._

  "range" should "calculate correct boundaries" in {
    def fs(chunkSize: Size): FileSettings = FileSettings(30.mbytes, chunkSize)

    bytes(Some(80), Some(210))(fs(100.bytes)) should be (Some(Range(Ior.both(0->80, 3->10))))
    bytes(Some(50), Some(100))(fs(100.bytes)) should be (Some(Range(Ior.both(0->50, 2->50))))
    bytes(Some(680), None)(fs(250.bytes)) should be (Some(Range(Ior.left(2 -> 180))))
    bytes(Some(680), Some(1212))(fs(250.bytes)) should be (Some(Range(Ior.both(2->180, 6->108))))
    bytes(Some(5 * 1024 * 1020), Some(6 * 1024 * 1002))(fs(256.kbytes)) should be (
      Some(Range(Ior.both(19->241664, 25->155648)))
    )
    bytes(Some(500), Some(100))(fs(15000.bytes)) should be (Some(Range(Ior.both(0->500, 1->14400))))
    bytes(None, Some(1024))(fs(15000.bytes)) should be (Some(Range(Ior.right(1->13976))))
    bytes(None, Some(15000))(fs(15000.bytes)) should be (Some(Range(Ior.right(1->0))))
  }

  it should "calculate correct boundaries at end of data" in {
    byteRange(Ior.both(22, 28))(FileSettings(28.bytes, 10.bytes)) should be (
      Some(Range(Ior.left((2,2))))
    )

    // length = 6773039
    byteRange(Ior.both(6707503, 6773038))(FileSettings(6773039.bytes, 256.kbytes)) should be (
      Some(Range(Ior.both((25, 153903), (1, 0))))
    )

    byteRange(Ior.both(6553600, 6707502))(FileSettings(6773039.bytes, 256.kbytes)) should be (
      Some(Range(Ior.both((25, 0), (1, 65536))))
    )

    byteRange(Ior.both(6269010, 6707502))(FileSettings(6773039.bytes, 256.kbytes)) should be (
      Some(Range(Ior.both((23, 239698), (2, 65536))))
    )
  }

  it should "return none when requesting outside of length" in {
    byteRange(Ior.both(22, 36))(FileSettings(28.bytes, 10.bytes)) should be (
      None
    )
  }
}
