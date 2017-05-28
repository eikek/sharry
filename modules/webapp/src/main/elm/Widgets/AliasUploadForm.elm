module Widgets.AliasUploadForm exposing (..)

import Html exposing (Html, button, form, h3, div, label, text, textarea, select, option, i, input, a, p)
import Html.Attributes exposing (class, name, type_, href, classList, rows, placeholder, value, selected)
import Html.Events exposing (onInput, onClick)

import Ports
import Resumable
import Resumable.Update as ResumableUpdate
import Data exposing (RemoteConfig, defer, bytesReadable)
import Widgets.MarkdownHelp as MarkdownHelp

type alias Limits =
    { maxFileSize: Int
    , maxFiles: Int
    }

type alias Model =
    { errorMessage: Maybe String
    , showMarkdownHelp: Bool
    , description: String
    , limits: Limits
    , resumableModel: Resumable.Model
    }

emptyModel: RemoteConfig -> Model
emptyModel cfg =
    Model Nothing False "" (Limits cfg.maxFileSize cfg.maxFiles) Resumable.emptyModel

clearModel: Model -> Model
clearModel model =
    Model Nothing False "" model.limits (Resumable.clearModel model.resumableModel)

hasError: Model -> Bool
hasError model =
    Data.isPresent model.errorMessage || Data.nonEmpty model.resumableModel.errorFiles

isReady: Model -> Bool
isReady model =
    (not <| Data.isPresent model.errorMessage) && (List.length model.resumableModel.files) > 0

errorMessage: Model -> List String
errorMessage model =
    let
        resumableErrors = Resumable.makeErrorList model.resumableModel
    in
        model.errorMessage
            |> Maybe.map List.singleton
            |> Maybe.map ((++) resumableErrors)
            |> Maybe.withDefault resumableErrors


type Msg
    = SetDescription String
    | ResumableMsg Resumable.Msg
    | ToggleMarkdownHelp

update: Msg -> Model -> (Model, Cmd Msg, Cmd Msg)
update msg model =
    case msg of
        SetDescription desc ->
            ({model | description = desc, errorMessage = Nothing}, Cmd.none) |> defer Cmd.none

        ResumableMsg msg ->
            let
                (rmodel, cmd) = ResumableUpdate.update msg model.resumableModel
            in
                {model | resumableModel = rmodel} ! [] |> defer (Cmd.map ResumableMsg cmd)

        ToggleMarkdownHelp ->
            {model | showMarkdownHelp = not model.showMarkdownHelp} ! [] |> defer Cmd.none


view: Model -> Html Msg
view model =
    if model.showMarkdownHelp then markdownHelp
    else
    form [classList [("ui form", True)
                    ,("error", hasError model)
                    ]
         ]
    [
     infoView model.limits
    ,div [class "ui error message"]
        [errorMessage model |> Data.messagesToHtml]
    ,div [class "field"]
        [
         label [][text "Description (supports "
                 ,a[onClick ToggleMarkdownHelp, class "ui link"][text "Markdown"]
                 ,text ")"
                 ]
        , textarea [name "description"
                   , rows 5
                   , onInput SetDescription
                   , placeholder "Optional description"
                   , value model.description
                   ][]
        ]
    ,div[]
        [
         a [class ("ui button " ++ Resumable.browseCssClass)][text "Add files"]
        ]
    ,div [class ("ui center aligned container " ++ Resumable.dropCssClass)]
        [
         p []
             [
              text "Drop files here or use the “Add files” button to select files to upload."
             ]
        ,makeFilesView model.resumableModel.files
        ]
    ]


makeFilesView: List Resumable.File -> Html Msg
makeFilesView files =
    let
        size = List.sum (List.map (\m -> m.size) files)
        bytes = bytesReadable Data.B (toFloat size)
        message = "Selected " ++ (toString (List.length files)) ++ " files, " ++ bytes
    in
        h3 [class "header"][text message]

infoView: Limits -> Html Msg
infoView cfg =
    p []
        [text ("You can select up to " ++
                   (toString cfg.maxFiles) ++
                   " files with a total of " ++
                   (bytesReadable Data.B (toFloat cfg.maxFileSize)) ++
                   ".")
        ]

markdownHelp:Html Msg
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
