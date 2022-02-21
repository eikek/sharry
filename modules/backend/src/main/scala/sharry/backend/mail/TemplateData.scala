package sharry.backend.mail

import sharry.backend.mustache.YamuscaCommon._
import sharry.common._

import yamusca.derive._
import yamusca.implicits._
import yamusca.imports._

case class TemplateData(
    user: Ident,
    url: LenientUri,
    password: Boolean,
    aliasName: String
)

object TemplateData {

  implicit val mustacheValue: ValueConverter[TemplateData] =
    deriveValueConverter[TemplateData]
}
