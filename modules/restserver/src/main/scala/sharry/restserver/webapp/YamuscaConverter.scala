package sharry.restserver.webapp

import sharry.backend.mustache.YamuscaCommon
import sharry.restapi.model.AppConfig
import sharry.restapi.model.OAuthItem

import yamusca.implicits._
import yamusca.imports._

object YamuscaConverter extends YamuscaCommon {

  implicit def yamuscaOAuthItemConverter: ValueConverter[OAuthItem] =
    ValueConverter.deriveConverter[OAuthItem]

  implicit def yamuscaAppConfigValueConverter: ValueConverter[AppConfig] =
    ValueConverter.deriveConverter[AppConfig]

}
