module Page.OpenDetail.Data exposing
    ( Model
    , Msg(..)
    , emptyModel
    , emptyPassModel
    )

import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.ShareDetail exposing (ShareDetail)
import Api.Model.ShareFile exposing (ShareFile)
import Comp.PasswordInput
import Comp.ShareFileList
import Http


type alias Model =
    { share : ShareDetail
    , fileListModel : Comp.ShareFileList.Model
    , message : Maybe BasicResult
    , fileView : Comp.ShareFileList.ViewMode
    , zoom : Maybe ShareFile
    , password : PassModel
    }


type alias PassModel =
    { model : Comp.PasswordInput.Model
    , field : Maybe String
    , enabled : Bool
    , badPassword : Bool
    }


emptyPassModel : PassModel
emptyPassModel =
    { model = Comp.PasswordInput.init
    , field = Nothing
    , enabled = False
    , badPassword = False
    }


emptyModel : Model
emptyModel =
    { share = Api.Model.ShareDetail.empty
    , fileListModel = Comp.ShareFileList.init
    , message = Nothing
    , fileView = Comp.ShareFileList.ViewList
    , zoom = Nothing
    , password = emptyPassModel
    }


type Msg
    = Init String
    | DetailResp (Result Http.Error ShareDetail)
    | FileListMsg Comp.ShareFileList.Msg
    | SetFileView Comp.ShareFileList.ViewMode
    | QuitZoom
    | SetZoom ShareFile
    | PasswordMsg Comp.PasswordInput.Msg
    | SubmitPassword
