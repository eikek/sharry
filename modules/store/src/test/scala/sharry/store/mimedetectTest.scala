package sharry.store

import java.io.InputStream
import org.scalatest._
import sharry.common.mime._
import mimedetect._

class MimedetectTest extends FlatSpec with Matchers {

  def resource(name: String): InputStream =
    Option(getClass.getResourceAsStream(name)).get

  "detect" should "work for bytes and names" in {
    mimedetect.fromIs(resource("/files/file.pdf"), MimeInfo.none) should be (
      MimeType.`application/pdf`)
    mimedetect.fromName("file.pdf", "") should be (
      MimeType.`application/pdf`)
  }
}
