module Pages.AliasUpload.Model exposing (..)

import Http

import Resumable
import Data exposing (Account, Alias, RemoteConfig)
import Widgets.AliasUploadForm as AliasUploadForm
import Widgets.UploadProgress as UploadProgress

type Mode
    = Form
    | Upload
    | Done

type alias Model =
    {cfg: RemoteConfig
    ,alia: Maybe Alias
    ,uploadForm: AliasUploadForm.Model
    ,uploadProgress: UploadProgress.Model
    ,mode: Mode
    ,errorMessage: String
    ,account: Maybe Account
    }

emptyModel: RemoteConfig -> Maybe Account -> Model
emptyModel cfg acc =
    Model cfg Nothing (AliasUploadForm.emptyModel cfg) UploadProgress.emptyModel Form "" acc

makeModel: RemoteConfig -> Maybe Account -> Alias -> Model
makeModel cfg acc alia =
    let
        empty = emptyModel cfg acc
    in
        {empty | alia = Just alia}

clearModel: Model -> Model
clearModel model =
    { cfg = model.cfg
    , alia = model.alia
    , uploadForm = AliasUploadForm.clearModel model.uploadForm
    , uploadProgress = UploadProgress.emptyModel
    , mode = Form
    , errorMessage = ""
    , account = model.account
    }

isAliasUser: Model -> Bool
isAliasUser model =
    case (model.account, model.alia) of
        (Just ac, Just al) ->
            ac.login == al.login
        _ ->
            False

isValidAlias: Model -> Bool
isValidAlias model =
    model.alia
        |> Maybe.map .enable
        |> Maybe.withDefault False


hasError: Model -> Bool
hasError model =
    not <| String.isEmpty model.errorMessage

clearError: Model -> Model
clearError model =
    {model | errorMessage = ""}


type Msg
    = AliasUploadFormMsg AliasUploadForm.Msg
    | UploadProgressMsg UploadProgress.Msg
    | InitUpload
    | UploadCreated (Result Http.Error ())
    | CancelUpload
    | ResetForm
    | UploadDeleted (Result Http.Error Int)

makeResumableMsg: Resumable.Msg -> List Msg
makeResumableMsg rmsg =
    [AliasUploadFormMsg (AliasUploadForm.ResumableMsg rmsg)
    ,UploadProgressMsg (UploadProgress.ResumableMsg rmsg)
    ]
