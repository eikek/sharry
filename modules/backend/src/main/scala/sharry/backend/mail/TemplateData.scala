package sharry.backend.mail

import yamusca.imports._
import yamusca.implicits._

import sharry.common._
import sharry.backend.mustache.YamuscaCommon._

case class TemplateData(user: Ident, url: LenientUri, password: Boolean, aliasName: String)

object TemplateData {

  implicit val mustacheValue: ValueConverter[TemplateData] =
    ValueConverter.deriveConverter[TemplateData]
}
