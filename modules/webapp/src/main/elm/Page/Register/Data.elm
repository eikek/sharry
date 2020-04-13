module Page.Register.Data exposing (..)

import Api.Model.BasicResult exposing (BasicResult)
import Comp.LanguageChoose
import Http
import Messages exposing (Language)


type alias Model =
    { result : Maybe BasicResult
    , login : String
    , pass1 : String
    , pass2 : String
    , showPass1 : Bool
    , showPass2 : Bool
    , errorMsg : List String
    , loading : Bool
    , successMsg : String
    , invite : Maybe String
    , langChoose : Comp.LanguageChoose.Model
    }


emptyModel : Model
emptyModel =
    { result = Nothing
    , login = ""
    , pass1 = ""
    , pass2 = ""
    , showPass1 = False
    , showPass2 = False
    , errorMsg = []
    , successMsg = ""
    , loading = False
    , invite = Nothing
    , langChoose = Comp.LanguageChoose.init
    }


type Msg
    = SetLogin String
    | SetPass1 String
    | SetPass2 String
    | SetInvite String
    | RegisterSubmit
    | ToggleShowPass1
    | ToggleShowPass2
    | SubmitResp (Result Http.Error BasicResult)
    | LangChooseMsg Comp.LanguageChoose.Msg
