module Pages.Login.Model exposing (..)

import Data exposing (RemoteUrls)

type alias Model =
    { login: String
    , password: String
    , error: String
    , loginUrl: String
    }

emptyModel: Model
emptyModel =
    Model "" "" "" ""

sharryModel: RemoteUrls -> Model
sharryModel urls =
    Model "sharry" "sharry" "" urls.authLogin

fromUrls: RemoteUrls -> Model
fromUrls urls =
    Model "" "" "" urls.authLogin
