module Pages.Upload.Model exposing(..)

import Http
import Data exposing (Account, RemoteConfig, UploadInfo)
import Resumable
import Widgets.UploadForm as UploadForm
import Widgets.UploadProgress as UploadProgress

type Mode
    = Settings
    | Upload
    | Publish

type alias Model =
    { uploadFormModel: UploadForm.Model
    , uploadProgressModel: UploadProgress.Model
    , mode: Mode
    , serverConfig: RemoteConfig
    , errorMessage: String
    }

emptyModel: RemoteConfig -> Model
emptyModel cfg =
    Model (UploadForm.emptyModel cfg) UploadProgress.emptyModel Settings cfg ""

clearModel: Model -> Model
clearModel model =
    { uploadFormModel = UploadForm.clearModel model.uploadFormModel
    , uploadProgressModel = UploadProgress.emptyModel
    , mode = Settings
    , serverConfig = model.serverConfig
    , errorMessage = ""
    }

hasError: Model -> Bool
hasError model =
    not <| String.isEmpty model.errorMessage

clearError: Model -> Model
clearError model =
    {model | errorMessage = ""}


type Msg
    = UploadFormMsg UploadForm.Msg
    | UploadProgressMsg UploadProgress.Msg
    | MoveToUpload
    | UploadCreated (Result Http.Error ())
    | MoveToPublish
    | ResetForm
    | CancelUpload
    | UploadDeleted (Result Http.Error Int)
    | UploadPublished (Result Http.Error UploadInfo)


resumableMsg: Resumable.Msg -> List Msg
resumableMsg rmsg =
    [UploadFormMsg (UploadForm.ResumableMsg rmsg)
    ,UploadProgressMsg (UploadProgress.ResumableMsg rmsg)
    ]

randomPasswordMsg: String -> Msg
randomPasswordMsg s =
    UploadFormMsg (UploadForm.RandomPassword s)
