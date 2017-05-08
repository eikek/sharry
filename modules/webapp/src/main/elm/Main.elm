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
                   Cmd.map LoginMsg (LoginCmd.authenticate (LoginModel.sharryModel flags.remoteConfig.urls))
              ,cmd_
              ]
    in
        (model_, cmd)


fileAddedMsg: (Resumable.Handle, Resumable.File) -> Msg
fileAddedMsg (h, f) =
    ResumableMsg h (Resumable.FileAdded f)

fileProgressMsg: (Resumable.Handle, Float) -> Msg
fileProgressMsg (h, percent) =
    ResumableMsg h (Resumable.Progress percent)

fileErrorMsg: (Resumable.Handle, String,  Resumable.File) -> Msg
fileErrorMsg (h, msg, file) =
    ResumableMsg h (Resumable.FileError file msg)

fileSuccessMsg: (Resumable.Handle, Resumable.File) -> Msg
fileSuccessMsg (h, file) =
    ResumableMsg h (Resumable.FileSuccess file)

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
        ]


main =
    Navigation.programWithFlags UrlChange
        { init = init
        , view = App.View.view
        , update = App.Update.update
        , subscriptions = subscriptions
        }
