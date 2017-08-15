module Pages.Login.Model exposing (..)

import Data exposing (RemoteUrls)

type alias Model =
    { login: String
    , password: String
    , error: String
    , loginUrl: String
    , welcomeMessage: String
    }

emptyModel: Model
emptyModel =
    Model "" "" "" "" ""

sharryModel: RemoteUrls -> String -> Model
sharryModel urls =
    Model "sharry" "sharry" "" urls.authLogin

fromUrls: RemoteUrls -> String -> Model
fromUrls urls =
    Model "" "" "" urls.authLogin
