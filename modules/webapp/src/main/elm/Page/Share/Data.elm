module Page.Share.Data exposing (Model, Msg(..), emptyModel, makeProps)

import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.IdResult exposing (IdResult)
import Api.Model.ShareProperties exposing (ShareProperties)
import Comp.Dropzone2
import Comp.IntField
import Comp.MarkdownInput
import Comp.PasswordInput
import Comp.ValidityField
import Data.Flags exposing (Flags)
import Data.UploadDict exposing (UploadDict)
import Data.UploadState exposing (UploadState)
import Data.ValidityOptions
import Data.ValidityValue exposing (ValidityValue)
import Http


type alias Model =
    { dropzoneModel : Comp.Dropzone2.Model
    , uploads : UploadDict
    , validityModel : Comp.ValidityField.Model
    , validityField : ValidityValue
    , passwordModel : Comp.PasswordInput.Model
    , passwordField : Maybe String
    , maxViewModel : Comp.IntField.Model
    , maxViewField : Maybe Int
    , descModel : Comp.MarkdownInput.Model
    , descField : String
    , nameField : Maybe String
    , formState : BasicResult
    , uploading : Bool
    , shareId : Maybe String
    , uploadPaused : Bool
    }


emptyModel : Flags -> Model
emptyModel flags =
    { dropzoneModel = Comp.Dropzone2.init
    , uploads = Data.UploadDict.empty
    , validityModel = Comp.ValidityField.init flags
    , validityField = Data.ValidityOptions.defaultValidity flags |> Tuple.second
    , passwordModel = Comp.PasswordInput.init
    , passwordField = Nothing
    , maxViewModel = Comp.IntField.init (Just 1) Nothing
    , maxViewField = Just 30
    , descModel = Comp.MarkdownInput.init
    , descField = ""
    , nameField = Nothing
    , formState = BasicResult True ""
    , uploading = False
    , shareId = Nothing
    , uploadPaused = False
    }


type Msg
    = DropzoneMsg Comp.Dropzone2.Msg
    | ValidityMsg Comp.ValidityField.Msg
    | PasswordMsg Comp.PasswordInput.Msg
    | MaxViewMsg Comp.IntField.Msg
    | DescMsg Comp.MarkdownInput.Msg
    | SetName String
    | ClearFiles
    | Submit
    | CreateShareResp (Result Http.Error IdResult)
    | Uploading UploadState
    | StartStopUpload
    | UploadStopped (Maybe String)
    | ResetForm


makeProps : Model -> ShareProperties
makeProps model =
    { name = model.nameField
    , validity = Data.ValidityValue.toMillis model.validityField
    , description = Just model.descField
    , maxViews = Maybe.withDefault 10 model.maxViewField
    , password = model.passwordField
    }
