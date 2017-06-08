module Pages.Upload.Model exposing(..)

import Http
import Data exposing (Account, RemoteConfig, UploadInfo)
import Resumable
import Widgets.UploadForm as UploadForm
import Widgets.UploadProgress as UploadProgress
import Widgets.MarkdownEditor as MarkdownEditor

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
    , markdownEditorModel: Maybe MarkdownEditor.Model
    , showMarkdownHelp: Bool
    }

emptyModel: RemoteConfig -> Model
emptyModel cfg =
    Model (UploadForm.emptyModel cfg) UploadProgress.emptyModel Settings cfg "" Nothing False

clearModel: Model -> Model
clearModel model =
    { uploadFormModel = UploadForm.clearModel model.uploadFormModel
    , uploadProgressModel = UploadProgress.emptyModel
    , mode = Settings
    , serverConfig = model.serverConfig
    , errorMessage = ""
    , markdownEditorModel = Nothing
    , showMarkdownHelp = False
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
    | ToggleMarkdownEditor
    | MarkdownEditorMsg MarkdownEditor.Msg
    | ToggleMarkdownHelp


resumableMsg: Resumable.Msg -> List Msg
resumableMsg rmsg =
    [UploadFormMsg (UploadForm.ResumableMsg rmsg)
    ,UploadProgressMsg (UploadProgress.ResumableMsg rmsg)
    ]

randomPasswordMsg: String -> Msg
randomPasswordMsg s =
    UploadFormMsg (UploadForm.RandomPassword s)
