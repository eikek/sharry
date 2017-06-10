module Pages.AliasUpload.View exposing (..)

import Html exposing (Html, a, div, text, h1, h2, h3, button, i)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)

import Data
import Pages.AliasUpload.Model exposing (..)
import Widgets.AliasUploadForm as AliasUploadForm
import Widgets.UploadProgress as UploadProgress
import Widgets.MarkdownEditor as MarkdownEditor
import Widgets.MarkdownHelp as MarkdownHelp

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
                [(mainView model)]


mainView: Model -> Html Msg
mainView model =
    div [class "main ui grid container"]
        [
         (userDimmer model)
        ,(emptyAliasDimmer model)
        ,div [class "sixteen wide column"]
             [h1 [class "ui header"][text "Upload your files here"]
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

stepView: Model -> List (Html Msg)
stepView model =
    case model.mode of
        Form ->
            [
            button [class "ui basic button", onClick ToggleMarkdownEditor][text "Description Editor"]
            ,(Html.map AliasUploadFormMsg (AliasUploadForm.view model.uploadForm))
            ,(uploadButton model)
            ,(cancelButton model)
            ]

        Upload ->
            [
             Html.map UploadProgressMsg (UploadProgress.view model.uploadProgress)
            ,(doneMessage model)
            ,(cancelButton model)
            ,(moreButton model)
            ]

        Done ->
            [div [][text "Everything uploaded."]]

userDimmer: Model -> Html Msg
userDimmer model =
    div [classList [("ui inverted dimmer", True)
                   ,("active", isAliasUser model)]]
        [
         div [class "content"]
             [
              div [class "ui center aligned grid"]
                  [
                   div [class "sixteen wide column"]
                       [
                        h2 [class "ui icon header"]
                            [
                             i [class "info icon"][]
                            ,text "Let me explain…"
                            ]
                       ]
                  ,div [class "eight wide column"]
                      [
                       div [class "ui info message"]
                           [Data.markdownHtml
                                """This page is not intended for
                                 you. Rather give the URL away to
                                 other, _anonymous_, users to allow
                                 them sending files to you. You
                                 receive all files uploaded through
                                 this page in _My Uploads_."""

                           ]
                      ]
                  ]
             ]
        ]

emptyAliasDimmer: Model -> Html Msg
emptyAliasDimmer model =
    div [classList [("ui dimmer", True)
                   ,("active", not (isValidAlias model))]]
        [div [class "content"]
             [div [class "ui center aligned grid"]
                  [div [class "sixteen wide column"]
                       [h2 [class "ui inverted icon header"]
                            [i [class "warning sign icon"][]
                            ,text "Not Found"
                            ]
                       ]
                  ,div [class "eight wide column"]
                      [div [class "ui inverted error message"]
                           [text "The alias was not found"]
                      ]
                  ]
             ]
        ]

doneMessage: Model -> Html Msg
doneMessage model =
    if nextStepDisabled Done model || UploadProgress.hasErrors model.uploadProgress then
        div[][]
    else
        div [class "ui success message"]
            [
             div [class "header"][text "All done."]
            ,div [class "content"]
                [Data.markdownHtml
                     """Your files have been uploaded. If you changed
                     your mind, you can remove them by clicking the
                     _Delete_ button. To upload more, simply refresh
                     the page or click the _More…_ button."""

                ]
            ]

moreButton: Model -> Html Msg
moreButton model =
    if nextStepDisabled Done model then
        div[][]
    else
        button [class "ui primary button", onClick ResetForm]
            [
             i [class "add icon"][]
            ,text "More …"
            ]

uploadButton: Model -> Html Msg
uploadButton model =
    button [classList [("ui primary button", True)
                      ,("disabled", nextStepDisabled Upload model)
                      ]
           , onClick InitUpload
           ]
    [i [class "upload icon"][]
    ,text "Upload"
    ]

cancelButton: Model -> Html Msg
cancelButton model =
    let
        action = if model.mode == Upload then CancelUpload else ResetForm
        btntext = if model.mode == Form then
                      "Reset"
                  else if UploadProgress.isComplete model.uploadProgress then
                      "Delete"
                  else
                      "Cancel"
    in
    a [class "ui labeled basic icon button", onClick action]
        [
         i [class "cancel icon"][]
        ,text btntext
        ]

renderError: Model -> Html Msg
renderError model =
    if hasError model then
        div [class "ui error message"]
            [text model.errorMessage]
    else
        div [][]

nextStepDisabled: Mode -> Model -> Bool
nextStepDisabled mode model =
    case (model.mode, mode) of
        (Form, Upload) ->
            not (AliasUploadForm.isReady model.uploadForm)

        (Upload, Done) ->
            not (UploadProgress.isComplete model.uploadProgress)

        _ ->
            True
