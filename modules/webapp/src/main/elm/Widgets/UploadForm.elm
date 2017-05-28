module Widgets.UploadForm exposing (..)

import Html exposing (Html, button, form, h1, h3, div, label, text, textarea, select, option, i, input, a, p)
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
    , maxValidity: String
    }

type alias Model =
    { errorMessage: Maybe String
    , showMarkdownHelp: Bool
    , description: String
    , validityNum: Int
    , validityNumStr: String
    , validityUnit: String
    , maxDownloads: Int
    , maxDownloadsStr: String
    , password: String
    , showPassword: Bool
    , limits: Limits
    , resumableModel: Resumable.Model
    }

emptyModel: RemoteConfig -> Model
emptyModel cfg =
    {errorMessage = Nothing
    ,showMarkdownHelp = False
    ,description = ""
    ,validityNum = 5
    ,validityNumStr = "5"
    ,validityUnit = "d"
    ,maxDownloads = 30
    ,maxDownloadsStr = "30"
    ,password = ""
    ,showPassword = False
    ,limits = Limits cfg.maxFileSize cfg.maxFiles cfg.maxValidity
    ,resumableModel = Resumable.emptyModel
    }

clearModel: Model -> Model
clearModel model =
    {errorMessage = Nothing
    ,showMarkdownHelp = False
    ,description = ""
    ,validityNum = 5
    ,validityNumStr = "5"
    ,validityUnit = "d"
    ,maxDownloads = 30
    ,maxDownloadsStr = "30"
    ,password = ""
    ,showPassword = False
    ,limits = model.limits
    ,resumableModel = Resumable.clearModel model.resumableModel
    }

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
    = SetValidityNum String
    | SetValidityUnit String
    | SetMaxDownloads String
    | SetDescription String
    | SetPassword String
    | GeneratePassword
    | RandomPassword String
    | TogglePasswordVisible
    | ResumableMsg Resumable.Msg
    | ToggleMarkdownHelp

updateNumber: String -> Model -> (Int -> Model -> Model) -> Model
updateNumber str model apply =
    case (String.toInt str) of
        Ok n ->
            if n > 0 then
                let
                    model_ = apply n model
                in
                    {model_| errorMessage = Nothing}
            else
                {model | errorMessage = Just "It must be a positive number!"}
        Err msg ->
            if str == "" then
                {model | errorMessage = Just "A number is requred"}
            else
                {model | errorMessage = Just ("Error converting number: "++msg)}


update: Msg -> Model -> (Model, Cmd Msg, Cmd Msg)
update msg model =
    case msg of
        SetValidityNum str ->
            let
                model_ = {model | validityNumStr = str}
                apply n m = {m | validityNum = n}
            in
                updateNumber str model_ apply ! [] |> defer Cmd.none

        SetValidityUnit unit ->
            ({model | validityUnit = unit, errorMessage = Nothing}, Cmd.none) |> defer Cmd.none

        SetMaxDownloads str ->
            let
                model_ = {model | maxDownloadsStr = str}
                apply n m = {m | maxDownloads = n}
            in
                updateNumber str model_ apply ! [] |> defer Cmd.none

        SetDescription desc ->
            ({model | description = desc, errorMessage = Nothing}, Cmd.none) |> defer Cmd.none

        SetPassword pw ->
            ({model | password = pw, errorMessage = Nothing}, Cmd.none) |> defer Cmd.none

        GeneratePassword ->
            (model, Ports.makeRandomString "") |> defer Cmd.none

        RandomPassword s ->
            {model | password = s} ! [] |> defer Cmd.none

        TogglePasswordVisible ->
            {model | showPassword = not model.showPassword, errorMessage = Nothing} ! [] |> defer Cmd.none

        ResumableMsg msg ->
            let
                (rmodel, cmd) = ResumableUpdate.update msg model.resumableModel
            in
                {model | resumableModel = rmodel} ! [] |> defer (Cmd.map ResumableMsg cmd)

        ToggleMarkdownHelp ->
            {model | showMarkdownHelp = Debug.log "have it " not model.showMarkdownHelp} ! [] |> defer Cmd.none


view: Model -> Html Msg
view model =
    if model.showMarkdownHelp then markdownHelp model
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
    ,div [class "two fields"]
        [
         div [class "field"]
             [
              label [][text "Validity"]
             ,input [class "ui input"
                    ,onInput SetValidityNum
                    ,type_ "text"
                    ,placeholder "Number"
                    ,value model.validityNumStr][]
             ]
        ,div [class "field"]
            [
             label [][text "Unit"]
            ,select [onInput SetValidityUnit]
                (List.map
                     (\n -> case n of
                                (val, unit) -> option [value val, selected <| model.validityUnit == val][text unit])
                     [("h", "Hours"), ("d", "Days"), ("m", "Months")])
            ]
        ]
    ,div [class "field"]
        [
         label [][text "Max. Downloads"]
        ,input [ class "ui input"
               , type_ "text"
               , name "maxdownloads"
               , onInput SetMaxDownloads
               , placeholder "Maximum number of downloads"
               , value model.maxDownloadsStr][]
        ]
    ,div [class "field"]
        [
         label [][text "Password"]
        ,div [class "two fields"]
            [
             div [class "field"]
                 [
                  input [ class "ui input"
                        , type_ (if model.showPassword then "text" else "password")
                        , onInput SetPassword
                        , placeholder "Optional password"
                        , value model.password][]
                 ]
            ,div [class "field"]
                [
                 a [class "ui button"
                   , onClick TogglePasswordVisible
                   ]
                     [text (if model.showPassword then "Hide" else "Show")]
                ,a [class "ui button"
                   , onClick GeneratePassword
                   ]
                     [text "Generate"]
                ]
            ]
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
                   ". The maximum validity is " ++
                   (Data.formatDuration cfg.maxValidity) ++
                   ".")
        ]

markdownHelp: Model -> Html Msg
markdownHelp model =
    div [onClick ToggleMarkdownHelp]
        [h3 [class "ui horizontal clearing divider header"]
             [i [class "help icon"][]
             ,text "Markdown Help"
             ]
        ,div [class "ui center aligned segment"]
            [text "Click somewhere on the help text to close it."]
        ,MarkdownHelp.helpTextHtml
        ]
