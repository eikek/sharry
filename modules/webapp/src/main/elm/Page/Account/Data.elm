module Page.Account.Data exposing
    ( Model
    , Msg(..)
    , emptyModel
    )

import Api.Model.AccountDetail exposing (AccountDetail)
import Api.Model.AccountList exposing (AccountList)
import Api.Model.BasicResult exposing (BasicResult)
import Comp.AccountForm
import Comp.AccountTable
import Http


type alias Model =
    { selected : Maybe AccountDetail
    , searchResult : List AccountDetail
    , query : String
    , tableModel : Comp.AccountTable.Model
    , formModel : Comp.AccountForm.Model
    , saveResult : Maybe BasicResult
    }


emptyModel : Model
emptyModel =
    { selected = Nothing
    , searchResult = []
    , query = ""
    , saveResult = Nothing
    , tableModel = Comp.AccountTable.init
    , formModel = Comp.AccountForm.initNew
    }


type Msg
    = Init (Maybe String)
    | SearchResp (Result Http.Error AccountList)
    | LoadResp (Result Http.Error AccountDetail)
    | SetQuery String
    | AccountTableMsg Comp.AccountTable.Msg
    | AccountFormMsg Comp.AccountForm.Msg
    | SaveResp (Result Http.Error BasicResult)
