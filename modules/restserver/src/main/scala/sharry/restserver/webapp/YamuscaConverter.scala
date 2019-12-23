package sharry.restserver.webapp

import yamusca.imports._
import yamusca.implicits._
import sharry.restapi.model.AppConfig
import sharry.restapi.model.OAuthItem
import sharry.backend.mustache.YamuscaCommon

object YamuscaConverter extends YamuscaCommon {

  implicit def yamuscaOAuthItemConverter: ValueConverter[OAuthItem] =
    ValueConverter.deriveConverter[OAuthItem]

  implicit def yamuscaAppConfigValueConverter: ValueConverter[AppConfig] =
    ValueConverter.deriveConverter[AppConfig]

}
