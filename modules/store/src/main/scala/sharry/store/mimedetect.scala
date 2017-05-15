package sharry.store

import java.io.InputStream
import org.apache.tika.config.TikaConfig
import org.apache.tika.metadata.{HttpHeaders, Metadata, TikaMetadataKeys}
import org.apache.tika.mime.MediaType
import scodec.bits.ByteVector
import fs2.Stream
import sharry.common.mime._

object mimedetect {
  private val tika = new TikaConfig().getDetector

  private def convert(mt: MediaType): MimeType =
    Option(mt).map(_.toString).
      map(MimeType.parse).
      flatMap(_.toOption).
      map(normalize).
      getOrElse(MimeType.unknown)

  private def makeMetadata(info: MimeInfo): Metadata = {
    val md = new Metadata
    info.filename.
      foreach(md.set(TikaMetadataKeys.RESOURCE_NAME_KEY, _))
    info.advertisedMime.
      foreach(md.set(HttpHeaders.CONTENT_TYPE, _))
    md
  }

  def fromIs(in: InputStream, mimeInfo: MimeInfo): MimeType = {
    convert(tika.detect(in, makeMetadata(mimeInfo)))
  }

  def fromBytes(bv: ByteVector, mimeInfo: MimeInfo): MimeType = {
    convert(tika.detect(new java.io.ByteArrayInputStream(bv.toArray), makeMetadata(mimeInfo)))
  }

  def fromName(filename: String, advertised: String = ""): MimeType = {
    convert(tika.detect(null, makeMetadata(MimeInfo.file(filename).withAdvertised(advertised))))
  }

  def fromData[F[_]](data: Stream[F, ByteVector], info: MimeInfo): Stream[F, MimeType] = {
    data.take(1).map(bv => fromBytes(bv, info))
  }

  case class MimeInfo(filename: Option[String], advertisedMime: Option[String]) {
    def withFilename(name: String) = copy(filename = Some(name).filter(_.nonEmpty))
    def withAdvertised(mime: String) = copy(advertisedMime = Some(mime).filter(_.nonEmpty))
  }

  object MimeInfo {
    val none = MimeInfo(None, None)

    def apply(filename: String, advertisedMime: String): MimeInfo =
      MimeInfo(Some(filename), Some(advertisedMime))

    def file(name: String) = MimeInfo(Some(name), None)
  }

  // implicit class UrlMimeOps(url: Url) {
  //   def mimeType = url.fileName.map(n => fromName(n)).getOrElse(MimeType.unknown)
  // }

  private def normalize(in: MimeType): MimeType = in match {
    case MimeType(_, sub, p) if sub contains "xhtml" =>
      MimeType.`text/html`.copy(params = p)

    case _ => in
  }
}
