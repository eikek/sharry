module Resumable exposing (..)

import Json.Encode as Json
import Data exposing (RemoteConfig)

type alias Handle = String

type alias Config =
    { target: String
    , testTarget: String
    , chunkSize: Int
    , forceChunkSize: Bool
    , simultaneousUploads: Int
    , testChunks: Bool
    , maxFiles: Int
    , maxFileSize: Int
    , withCredentials: Bool
    , handle: Maybe Handle
    , dropClass: String
    , browseClass: String
    , page: String
    , headers: Json.Value
    }

browseCssClass: String
browseCssClass = "sharry-add-files"

dropCssClass: String
dropCssClass = "sharry-dropzone"

makeStandardConfig: RemoteConfig -> Config
makeStandardConfig cfg =
    { target = cfg.urls.uploadData
    , testTarget = cfg.urls.uploadData
    , chunkSize = cfg.chunkSize
    , simultaneousUploads = cfg.simultaneousUploads
    , maxFiles = cfg.maxFiles
    , maxFileSize = cfg.maxFileSize
    , forceChunkSize = True
    , testChunks = True
    , withCredentials = True
    , handle = Nothing
    , dropClass = "."++dropCssClass
    , browseClass = "."++browseCssClass
    , page = ""
    , headers = Json.object []
    }

makeAliasConfig: RemoteConfig -> String -> Config
makeAliasConfig cfg aliasId =
    let
        default = makeStandardConfig cfg
    in
        {default| headers = Json.object [(cfg.aliasHeaderName, Json.string aliasId)]}

type alias File =
    { fileName: String
    , size: Int
    , uniqueIdentifier: String
    , progress: Float
    , completed: Bool
    , uploading: Bool
    }

type State
    = Initial
    | Uploading
    | Paused
    | Cancelled
    | Completed

type alias Model =
    { handle: Maybe Handle
    , files: List File
    , progress: Float
    , errorFiles: List (File, String)
    , state: State
    }

emptyModel: Model
emptyModel =
    Model Nothing [] -1 [] Initial

{-| Clears everything but the handle to reuse a resumable instance.
-}
clearModel: Model -> Model
clearModel model =
    {emptyModel | handle = model.handle}

isInitialized: Model -> Bool
isInitialized model =
    case model.handle of
        Just h -> True
        Nothing -> False

hasErrors: Model -> Bool
hasErrors model =
    not <| List.isEmpty model.errorFiles

type Msg
    = Initialize Config
    | SetHandle Handle
    | FileAdded File
    | FileError File String
    | FileSuccess File
    | Progress Float
    | UploadStarted
    | UploadPaused
    | UploadComplete
