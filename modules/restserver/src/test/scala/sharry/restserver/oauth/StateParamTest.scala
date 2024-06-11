package sharry.restserver.oauth

import cats.effect.*

import munit.*
import scodec.bits.ByteVector

class StateParamTest extends CatsEffectSuite {

  private val key = ByteVector.fromValidHex("caffee")
  private val key2 = key ++ key

  test("generate") {
    for {
      p <- StateParam.generate[IO](key)
      _ = {
        assert(p.value.length > 8)
        assert(p.sig.nonEmpty)
        assert(p.isValid(key))
        assert(!p.isValid(key2))
      }
    } yield ()
  }

  test("fromString") {
    for {
      p <- StateParam.generate[IO](key)
      str = p.asString
      p2 = StateParam.fromString(str, key).fold(sys.error, identity)
      p3 = StateParam.fromString(str, key2)
      p4 = StateParam.fromString("uiaeuiaeue", key)
      p5 = StateParam.fromString(str + "$" + str, key)
      _ = {
        assertEquals(p2, p)
        assert(p3.isLeft)
        assert(p4.isLeft)
        assert(p5.isLeft)
      }
    } yield ()
  }
}
