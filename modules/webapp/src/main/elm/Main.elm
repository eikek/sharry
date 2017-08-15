module Main exposing (..)

import AnimationFrame
import Time exposing (Time, millisecond)
import App.Model exposing (..)
import App.Update
import App.View
import Data exposing (Account, RemoteConfig)
import Pages.Login.Model as LoginModel
import Pages.Login.Commands as LoginCmd
import Pages.Upload.Model as UploadModel
import Resumable
import Ports
import Navigation

type alias Flags =
    { account: Maybe Account
    , remoteConfig: RemoteConfig
    }

init: Flags -> Navigation.Location -> (Model, Cmd Msg)
init flags location =
    let
        hasAccount = Maybe.map (\a -> True) flags.account |> Maybe.withDefault False
        model = initModel flags.remoteConfig flags.account location
        (model_, cmd_) = App.Update.update (UrlChange location) model
        cmd = Cmd.batch
              [
               if flags.remoteConfig.authEnabled || hasAccount then
                   Cmd.none
               else
                   Cmd.map LoginMsg (LoginCmd.authenticate (LoginModel.sharryModel flags.remoteConfig.urls flags.remoteConfig.welcomeMessage))
              ,cmd_
              ]
    in
        (model_, cmd)


fileAddedMsg: (String, Resumable.File) -> Msg
fileAddedMsg (page, f) =
    ResumableMsg page (Resumable.FileAdded f)

fileProgressMsg: (String, Float) -> Msg
fileProgressMsg (page, percent) =
    ResumableMsg page (Resumable.Progress percent)

fileErrorMsg: (String, String,  Resumable.File) -> Msg
fileErrorMsg (page, msg, file) =
    ResumableMsg page (Resumable.FileError file msg)

fileSuccessMsg: (String, Resumable.File) -> Msg
fileSuccessMsg (page, file) =
    ResumableMsg page (Resumable.FileSuccess file)

fileMaxSizeError: (String, Resumable.File) -> Msg
fileMaxSizeError (page, file) =
    ResumableMsg page (Resumable.FileError file "The maximum size limit is exceeded!")

fileMaxCountError: (String, Resumable.File) -> Msg
fileMaxCountError (page, file) =
    ResumableMsg page (Resumable.FileError file "The maximum file count limit is exceeded!")

subscriptions: Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every (model.serverConfig.cookieAge * millisecond * 0.9) LoginRefresh
        , if model.deferred == [] then Sub.none else AnimationFrame.times DeferredTick
        , Ports.randomString RandomString
        , Ports.resumableHandle (\(page, h) -> ResumableMsg page (Resumable.SetHandle h))
        , Ports.resumableFileAdded fileAddedMsg
        , Ports.resumableProgress fileProgressMsg
        , Ports.resumableError fileErrorMsg
        , Ports.resumableFileSuccess fileSuccessMsg
        , Ports.resumableComplete (\h -> ResumableMsg h Resumable.UploadComplete)
        , Ports.resumableStarted (\h -> ResumableMsg h Resumable.UploadStarted)
        , Ports.resumablePaused (\h -> ResumableMsg h Resumable.UploadPaused)
        , Ports.resumableMaxFilesError fileMaxCountError
        , Ports.resumableMaxFileSizeError fileMaxSizeError
        ]


main =
    Navigation.programWithFlags UrlChange
        { init = init
        , view = App.View.view
        , update = App.Update.update
        , subscriptions = subscriptions
        }
