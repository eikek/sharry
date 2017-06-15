module Widgets.UploadProgress exposing (..)

import Html exposing (Html, div, text, i, a)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)

import Data
import Ports
import Resumable
import Resumable.Update as ResumableUpdate

type alias Model =
    { resumableModel: Resumable.Model
    }

progressClass: String
progressClass = "sharry-upload-progress"

emptyModel: Model
emptyModel =
    Model Resumable.emptyModel

isComplete: Model -> Bool
isComplete model =
    model.resumableModel.state == Resumable.Completed

hasErrors: Model -> Bool
hasErrors model =
    Resumable.hasErrors model.resumableModel

type Msg
    = ResumableMsg Resumable.Msg
    | PauseUpload
    | StartUpload
    | RetryUpload

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    let
        handle = Maybe.withDefault "" model.resumableModel.handle
    in
    case msg of
        ResumableMsg msg ->
            let
                (um, ucmd) = ResumableUpdate.update msg model.resumableModel
                progressCmd = \p -> Ports.setProgress ("."++progressClass, p, hasErrors model)
            in
                case msg of
                    Resumable.Initialize cfg ->
                        if isComplete model then
                            model ! [progressCmd 1.0]
                        else
                            model ! []

                    Resumable.Progress percent ->
                        {model | resumableModel = um} ! [Cmd.map ResumableMsg ucmd, progressCmd percent]
                    _ ->
                        {model | resumableModel = um} ! [Cmd.map ResumableMsg ucmd]

        PauseUpload ->
            (model, Ports.resumablePause handle)

        StartUpload ->
            (model, Ports.resumableStart handle)

        RetryUpload ->
            let
                rm = model.resumableModel
                selectIdent = Tuple.first >> (\f -> f.uniqueIdentifier)
            in
            {model | resumableModel = {rm | errorFiles = []}} ! [Ports.resumableRetry (handle, List.map selectIdent rm.errorFiles)]

toggleButton: Model -> Html Msg
toggleButton model =
    case model.resumableModel.state of
        Resumable.Uploading ->
            a [class "ui labeled basic icon button", onClick PauseUpload]
            [
             i [class "pause icon"][]
            ,text "Pause"
            ]
        Resumable.Paused ->
            a [class "ui labeled basic icon button", onClick StartUpload]
            [
             i [class "play icon"][]
            ,text "Start"
            ]
        _ -> div[][]

retryButton: Model -> Html Msg
retryButton model =
    if (isComplete model && hasErrors model) then
        a [class "ui labeled basic icon button", onClick RetryUpload]
            [
             i [class "retweet icon"][]
            ,text "Retry"
            ]
    else
        div[][]

view: Model -> Html Msg
view model =
    let
        message = if isComplete model then
                      if hasErrors model then "There were errors uploading some of your files." else "Done."
                  else
                      "Uploading Files"
    in
    div []
        [
         div [classList [("ui indicating progress " ++ progressClass, True)
                        ,("error", hasErrors model)]]
             [
              div [class "bar"]
                  [
                   div [class "progress"][text "{percent}"]
                  ]
             ,div [class "label"][text message]
             ]
        ,(toggleButton model)
        ,(retryButton model)
        ]
