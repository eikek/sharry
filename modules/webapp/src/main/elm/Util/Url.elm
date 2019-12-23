module Util.Url exposing (emptyHttp, emptyHttps)

import Url exposing (Url)


emptyHttp : Url
emptyHttp =
    Url Url.Http "" Nothing "" Nothing Nothing


emptyHttps : Url
emptyHttps =
    Url Url.Https "" Nothing "" Nothing Nothing
