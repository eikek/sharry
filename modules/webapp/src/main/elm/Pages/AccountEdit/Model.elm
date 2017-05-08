module Pages.AccountEdit.Model exposing(..)

import Http
import Data exposing (Account, RemoteUrls)

import Widgets.AccountForm as AccountForm
import Widgets.LoginSearch as LoginSearch

type alias Model =
    { search: LoginSearch.Model
    , accountForm: Maybe AccountForm.Model
    , errorMsg: String
    , urls: RemoteUrls
    }

emptyModel: RemoteUrls -> Model
emptyModel urls =
    Model (LoginSearch.initModel urls) Nothing "" urls

type Msg
    = NewAccount
    | AccountFormMsg AccountForm.Msg
    | LoginSearchMsg LoginSearch.Msg
