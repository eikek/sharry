package sharry.backend.mail

import sharry.backend.mustache.YamuscaCommon.*
import sharry.common.*

import yamusca.derive.*
import yamusca.implicits.*
import yamusca.imports.*

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
