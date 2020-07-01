module Page.Login.Data exposing (..)

import Api.Model.AuthResult exposing (AuthResult)
import Comp.LanguageChoose
import Http


type alias Model =
    { username : String
    , password : String
    , result : Maybe AuthResult
    , langChoose : Comp.LanguageChoose.Model
    }


empty : Model
empty =
    { username = ""
    , password = ""
    , result = Nothing
    , langChoose = Comp.LanguageChoose.init
    }


type Msg
    = SetUsername String
    | SetPassword String
    | Authenticate
    | AuthResp (Result Http.Error AuthResult)
    | Init
    | LangChooseMsg Comp.LanguageChoose.Msg
