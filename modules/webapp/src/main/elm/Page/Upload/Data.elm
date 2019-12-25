module Page.Upload.Data exposing (Model, Msg(..), emptyModel)

import Api.Model.ShareList exposing (ShareList)
import Api.Model.ShareListItem exposing (ShareListItem)
import Comp.ShareTable
import Http


type alias Model =
    { selected : Maybe ShareListItem
    , searchResult : List ShareListItem
    , query : String
    , tableModel : Comp.ShareTable.Model
    }


emptyModel : Model
emptyModel =
    { selected = Nothing
    , searchResult = []
    , query = ""
    , tableModel = Comp.ShareTable.init
    }


type Msg
    = ShareTableMsg Comp.ShareTable.Msg
    | SetQuery String
    | SearchResp (Result Http.Error ShareList)
    | Init
