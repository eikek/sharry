module Pages.Upload.View exposing (..)

import List
import Html exposing (Html, button, form, h1, div, label, text, textarea, select, option, i, input, a, p, h3)
import Html.Attributes exposing (class, name, type_, href, classList, rows, placeholder, value, selected)
import Html.Events exposing (onInput, onClick)

import Resumable
import Data exposing (Account, RemoteConfig, bytesReadable)
import Widgets.UploadForm as UploadForm
import Widgets.UploadProgress as UploadProgress
import Widgets.MarkdownEditor as MarkdownEditor
import Widgets.MarkdownHelp as MarkdownHelp
import Pages.Upload.Model exposing (..)
import Pages.Upload.Update exposing (..)

view: Model -> Html Msg
view model =
    case model.markdownEditorModel of
        Just mem ->
            div []
                [
                 div [class "main ui grid container"]
                     [
                      div [class "row"]
                          [button [class "ui primary button", onClick ToggleMarkdownEditor][text "Back"]
                          ,button [class "ui button", onClick ToggleMarkdownHelp][text "Help"]
                          ]
                     ,div [class "row"]
                         [
                          div [class "ui"]
                              [text "Write Markdown in the left input below and a preview is displayed "
                              ,text "at the right as you type. Click Help button to show syntax help."
                              ]
                         ]
                     ]
                ,if model.showMarkdownHelp then
                     markdownHelp
                 else
                     Html.map MarkdownEditorMsg (MarkdownEditor.view mem)
                ]

        Nothing ->
            div [class "main ui grid container"]
                (mainView model)


mainView: Model -> List (Html Msg)
mainView model =
    [
     div [class "sixteen wide column"]
         [h1 [class "ui header"][text "New Share"]
         ]
    ,div [class "sixteen wide column"]
        [(steps model)
        ,(renderError model)
        ]
    ,div [class "sixteen wide column"]
        (stepView model)
    ]

markdownHelp: Html Msg
markdownHelp =
    div [onClick ToggleMarkdownHelp]
        [h3 [class "ui horizontal clearing divider header"]
             [i [class "help icon"][]
             ,text "Markdown Help"
             ]
        ,div [class "ui center aligned segment"]
            [text "Click somewhere on the help text to close it."]
        ,MarkdownHelp.helpTextHtml
        ]

renderError: Model -> Html Msg
renderError model =
    if hasError model then
        div [class "ui error message"]
            [text model.errorMessage]
    else
        div [][]

cancelButton: Model -> Html Msg
cancelButton model =
    let
        action = if model.mode == Upload then CancelUpload else ResetForm
    in
    a [class "ui labeled right floated basic icon button", onClick action]
        [
         i [class "cancel icon"][]
        ,text (if model.mode == Settings then "Reset" else "Cancel")
        ]

stepView: Model -> List (Html Msg)
stepView model =
    case model.mode of
        Settings ->
                [
                 (cancelButton model)
                ,button [class "ui basic button", onClick ToggleMarkdownEditor][text "Description Editor"]
                ,Html.map UploadFormMsg (UploadForm.view model.uploadFormModel)
                ]

        Upload ->
                [
                 Html.map UploadProgressMsg (UploadProgress.view model.uploadProgressModel)
                ,(cancelButton model)
                ]
        Publish ->
            [div [][text "Oopps, this is an error."]]

nextStepDisabled: Mode -> Model -> Bool
nextStepDisabled mode model =
    case (model.mode, mode) of
        (Settings, Upload) ->
            not (UploadForm.isReady model.uploadFormModel)

        (Upload, Publish) ->
            not (UploadProgress.isComplete model.uploadProgressModel)

        _ ->
            True

stepClasses: Mode -> Model -> Html.Attribute msg
stepClasses mode model =
    classList [("active", model.mode == mode)
              ,("disabled", model.mode /= mode && (nextStepDisabled mode model))
              ,("step", True)
              ]

stepIcon: Mode -> String
stepIcon mode =
    case mode of
        Settings -> "ui settings icon"
        Upload -> "ui upload icon"
        Publish -> "ui share icon"

renderStep: Mode -> Maybe Msg -> Model -> Html Msg
renderStep mode msg model =
    let
        handler = (Maybe.withDefault [] (Maybe.map (\m -> [onClick m]) msg))
        parent = \cs -> if mode == model.mode then
                     div [(stepClasses mode model)] cs
                 else
                     a ([(stepClasses mode model)] ++ handler) cs
    in
        parent [ i [class (stepIcon mode)][]
               , div [class "content"]
                   [
                    div [class "title"]
                        [text (toString mode)]
                   ]
               ]

steps: Model -> Html Msg
steps model =
    div [class "ui three mini steps"]
        [
         (renderStep Settings Nothing model)
        ,(renderStep Upload (Just MoveToUpload) model)
        ,(renderStep Publish (Just MoveToPublish)  model)
        ]
