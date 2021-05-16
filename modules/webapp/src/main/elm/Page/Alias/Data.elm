module Page.Alias.Data exposing (Model, Msg(..), clipboardData, emptyModel)

import Api.Model.AliasDetail exposing (AliasDetail)
import Api.Model.AliasList exposing (AliasList)
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.IdResult exposing (IdResult)
import Comp.AliasForm
import Comp.AliasTable
import Comp.MailSend
import Data.Flags exposing (Flags)
import Http


type alias Model =
    { selected : Maybe AliasDetail
    , searchResult : List AliasDetail
    , query : String
    , tableModel : Comp.AliasTable.Model
    , formModel : Comp.AliasForm.Model
    , saveResult : Maybe BasicResult
    , mailForm : Maybe Comp.MailSend.Model
    }


emptyModel : Flags -> Model
emptyModel flags =
    { selected = Nothing
    , searchResult = []
    , query = ""
    , tableModel = Comp.AliasTable.init
    , formModel = Comp.AliasForm.initNew flags
    , saveResult = Nothing
    , mailForm = Nothing
    }


type Msg
    = Init (Maybe String)
    | SearchResp (Result Http.Error AliasList)
    | LoadResp (Result Http.Error AliasDetail)
    | SetQuery String
    | AliasTableMsg Comp.AliasTable.Msg
    | AliasFormMsg Comp.AliasForm.Msg
    | SaveResp (Result Http.Error IdResult)
    | DeleteResp (Result Http.Error BasicResult)
    | MailFormMsg Comp.MailSend.Msg
    | InitMail
    | InitNewAlias


clipboardData : ( String, String )
clipboardData =
    ( "Alias", "#alias-copy-to-clipboard-btn" )
