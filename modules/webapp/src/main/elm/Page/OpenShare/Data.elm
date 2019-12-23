module Page.OpenShare.Data exposing (Model, Msg(..), emptyModel)

import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.IdResult exposing (IdResult)
import Comp.Dropzone2
import Comp.MarkdownInput
import Data.UploadDict exposing (UploadDict)
import Data.UploadState exposing (UploadState)
import Dict exposing (Dict)
import File exposing (File)
import Http
import Json.Decode as D


type alias Model =
    { dropzoneModel : Comp.Dropzone2.Model
    , uploads : UploadDict
    , descModel : Comp.MarkdownInput.Model
    , descField : String
    , formState : BasicResult
    , uploading : Bool
    , shareId : Maybe String
    , uploadPaused : Bool
    }


emptyModel : Model
emptyModel =
    { dropzoneModel = Comp.Dropzone2.init
    , uploads = Data.UploadDict.empty
    , descModel = Comp.MarkdownInput.init
    , descField = ""
    , formState = BasicResult True ""
    , uploading = False
    , shareId = Nothing
    , uploadPaused = False
    }


type Msg
    = DropzoneMsg Comp.Dropzone2.Msg
    | DescMsg Comp.MarkdownInput.Msg
    | ClearFiles
    | Submit
    | CreateShareResp (Result Http.Error IdResult)
    | Uploading UploadState
    | StartStopUpload
    | UploadStopped (Maybe String)
    | ResetForm
    | NotifyResp (Result Http.Error BasicResult)
