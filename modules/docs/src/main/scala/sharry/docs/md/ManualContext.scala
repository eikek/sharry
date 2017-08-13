package sharry.docs.md

import yamusca.imports._
import yamusca.implicits._

case class ManualContext(
  versionLong: String
    , versionShort: String
    , `default-configuration`: String)

object ManualContext {
  implicit val valueConverter: ValueConverter[ManualContext] =
    ValueConverter.deriveConverter[ManualContext]
}
