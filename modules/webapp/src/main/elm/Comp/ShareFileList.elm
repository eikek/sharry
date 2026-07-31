module Comp.ShareFileList exposing
    ( FileAction(..)
    , Model
    , Msg(..)
    , Settings
    , ViewMode(..)
    , init
    , initWithFiles
    , previewPossible
    , reset
    , update
    , view
    )

import Api.Model.ShareFile exposing (ShareFile)
import Comp.ConfirmModal
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onCheck)
import Html.Keyed
import Messages.ShareFileList exposing (Texts)
import Set exposing (Set)
import Styles as S
import Util.Size


type alias Model =
    { embedOn : Set String
    , requestDelete : Maybe ShareFile
    , selectedFiles : Set String
    , detailsOpen : Set String
    }


type Msg
    = Select ShareFile
    | EmbedFile ShareFile
    | ReqDelete ShareFile
    | DeleteConfirm
    | DeleteCancel
    | ToggleZipFile String
    | SelectAllZip (List String)
    | DeselectAllZip
    | ToggleDetails ShareFile


type FileAction
    = FileNone
    | FileClick ShareFile
    | FileDelete ShareFile


type ViewMode
    = ViewList
    | ViewCard


init : Model
init =
    { embedOn = Set.empty
    , requestDelete = Nothing
    , selectedFiles = Set.empty
    , detailsOpen = Set.empty
    }


initWithFiles : List ShareFile -> Model -> Model
initWithFiles files model =
    { model | selectedFiles = Set.fromList (List.map .id files) }


reset : Model -> Model
reset model =
    { model | embedOn = Set.empty }


type alias Settings =
    { baseUrl : String
    , viewMode : ViewMode
    , delete : Bool
    , zipBaseUrl : Maybe String
    , zipMaxSize : Int
    }


update : Msg -> Model -> ( Model, FileAction )
update msg model =
    case msg of
        Select sf ->
            ( model
            , if previewPossible sf.mimetype then
                FileClick sf

              else
                FileNone
            )

        EmbedFile sf ->
            ( { model | embedOn = Set.insert sf.id model.embedOn }
            , FileNone
            )

        ReqDelete sf ->
            ( { model
                | requestDelete = Just sf
              }
            , FileNone
            )

        DeleteCancel ->
            ( { model | requestDelete = Nothing }, FileNone )

        DeleteConfirm ->
            case model.requestDelete of
                Just sf ->
                    ( { model | requestDelete = Nothing }
                    , FileDelete sf
                    )

                Nothing ->
                    ( model, FileNone )

        ToggleZipFile id ->
            let
                newSelected =
                    if Set.member id model.selectedFiles then
                        Set.remove id model.selectedFiles

                    else
                        Set.insert id model.selectedFiles
            in
            ( { model | selectedFiles = newSelected }, FileNone )

        SelectAllZip ids ->
            ( { model | selectedFiles = Set.fromList ids }, FileNone )

        DeselectAllZip ->
            ( { model | selectedFiles = Set.empty }, FileNone )

        ToggleDetails sf ->
            let
                newOpen =
                    if Set.member sf.id model.detailsOpen then
                        Set.remove sf.id model.detailsOpen

                    else
                        Set.insert sf.id model.detailsOpen
            in
            ( { model | detailsOpen = newOpen }, FileNone )



--- View


view : Texts -> Settings -> List ShareFile -> Model -> Html Msg
view texts settings files model =
    div []
        [ zipButton texts settings files model
        , case settings.viewMode of
            ViewList ->
                fileTable texts settings model files

            ViewCard ->
                fileCards texts settings model files
        ]


buildZipUrl : String -> Set String -> String
buildZipUrl baseUrl selected =
    if Set.isEmpty selected then
        baseUrl

    else
        let
            params =
                Set.toList selected
                    |> List.map (\id -> "file=" ++ id)
                    |> String.join "&"
        in
        baseUrl ++ "?" ++ params


selectedSize : List ShareFile -> Set String -> Int
selectedSize files selected =
    files
        |> List.filter (\f -> Set.member f.id selected)
        |> List.foldl (\f acc -> acc + f.size) 0


isFileChecked : Set String -> String -> Bool
isFileChecked selected id =
    Set.member id selected


zipButton : Texts -> Settings -> List ShareFile -> Model -> Html Msg
zipButton texts settings files model =
    case settings.zipBaseUrl of
        Nothing ->
            text ""

        Just baseUrl ->
            let
                showZip =
                    List.length files > 1

                noneSelected =
                    Set.isEmpty model.selectedFiles

                selSize =
                    selectedSize files model.selectedFiles

                overLimit =
                    settings.zipMaxSize > 0 && selSize > settings.zipMaxSize

                url =
                    buildZipUrl baseUrl model.selectedFiles

                allSelected =
                    Set.size model.selectedFiles == List.length files

                buttonLabel =
                    if allSelected then
                        texts.downloadAllZip

                    else
                        texts.downloadSelectedZip

                sizeLabel =
                    toFloat selSize
                        |> Util.Size.bytesReadable Util.Size.B

                limitLabel =
                    toFloat settings.zipMaxSize
                        |> Util.Size.bytesReadable Util.Size.B
            in
            div
                [ class
                    ("flex flex-col mb-2"
                        ++ (if showZip then "" else " hidden")
                    )
                ]
                [ div [ class "flex flex-row items-center justify-end space-x-2 mb-1" ]
                    [ span
                        [ class
                            ("text-sm text-gray-500 dark:text-stone-400"
                                ++ (if settings.zipMaxSize > 0 && not noneSelected then "" else " hidden")
                            )
                        ]
                        [ text (sizeLabel ++ texts.selectedSizeOf ++ limitLabel) ]
                    , button
                        [ class (S.secondaryBasicButton ++ " text-xs")
                        , onClick (SelectAllZip (List.map .id files))
                        ]
                        [ text texts.selectAll ]
                    , button
                        [ class (S.secondaryBasicButton ++ " text-xs")
                        , onClick DeselectAllZip
                        ]
                        [ text texts.deselectAll ]
                    ]
                , div [ class "flex flex-row justify-end" ]
                    [ span
                        [ class
                            ("text-sm text-yellow-600 dark:text-yellow-400 py-1"
                                ++ (if noneSelected then "" else " hidden")
                            )
                        ]
                        [ i [ class "fa fa-info-circle mr-1" ] []
                        , text texts.noFilesSelected
                        ]
                    , span
                        [ class
                            ("text-sm text-red-600 dark:text-red-400 py-1"
                                ++ (if overLimit then "" else " hidden")
                            )
                        ]
                        [ i [ class "fa fa-exclamation-triangle mr-1" ] []
                        , text texts.selectionTooLarge
                        ]
                    , a
                        [ class
                            (S.secondaryButton
                                ++ (if noneSelected || overLimit then " hidden" else "")
                            )
                        , href url
                        , title buttonLabel
                        ]
                        [ i [ class "fa fa-file-archive mr-2" ] []
                        , text buttonLabel
                        ]
                    ]
                ]


fileCards : Texts -> Settings -> Model -> List ShareFile -> Html Msg
fileCards texts settings model files =
    Html.Keyed.node "div"
        [ class "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4 gap-2" ]
        (List.map
            (\file ->
                let
                    key =
                        file.id
                            ++ (if Set.member file.id model.selectedFiles then
                                    ":1"

                                else
                                    ":0"
                               )
                in
                ( key, fileCard texts settings model file )
            )
            files
        )


fileCard : Texts -> Settings -> Model -> ShareFile -> Html Msg
fileCard texts settings model file =
    let
        deleteModal_ =
            modalSettings texts

        deleteModal =
            { deleteModal_
                | enabled = model.requestDelete == Just file
                , extraClass = "rounded"
            }

        checked =
            isFileChecked model.selectedFiles file.id
    in
    div
        [ class "relative hover:shadow-lg rounded flex flex-col break-words border border-gray-400 dark:border-stone-600 dark:hover:border-stone-500"
        , id file.id
        ]
        [ Comp.ConfirmModal.view deleteModal
        , div [ class "overflow-hidden block bg-gray-50 dark:bg-stone-700 dark:bg-opacity-40  border-gray-400 dark:hover:border-stone-500 rounded-t max-h-52" ]
            [ fileEmbed texts settings model file
            ]
        , div [ class "flex flex-col flex-grow px-2 my-2" ]
            [ div [ class "inline" ]
                [ case settings.zipBaseUrl of
                    Just _ ->
                        input
                            [ type_ "checkbox"
                            , Html.Attributes.checked checked
                            , onCheck (\_ -> ToggleZipFile file.id)
                            , class S.checkboxInput
                            , class "mr-2"
                            ]
                            []

                    Nothing ->
                        text ""
                , a
                    [ title texts.downloadToDisk
                    , download file.filename
                    , href (settings.baseUrl ++ file.id)
                    , class S.link
                    ]
                    [ text file.filename
                    ]
                , span [ class "ml-2" ]
                    [ text "("
                    , toFloat file.size |> Util.Size.bytesReadable Util.Size.B |> text
                    , text " · "
                    , text (texts.dateTime file.created)
                    , text ")"
                    ]
                ]
            , div [ class "mt-2 break-words " ]
                [ incompleteLabel texts file
                ]
            ]
        , div [ class "flex flex-col px-1 py-1" ]
            [ div [ class "flex flex-row space-x-1" ]
                [ a
                    [ class S.secondaryBasicButton
                    , title texts.downloadToDisk
                    , download file.filename
                    , href (settings.baseUrl ++ file.id)
                    ]
                    [ i [ class "fa fa-download" ] []
                    ]
                , a
                    [ classList
                        [ ( "invisible", not <| previewPossible file.mimetype )
                        ]
                    , class S.secondaryBasicButton
                    , title texts.viewInBrowser
                    , href "#"
                    , onClick (Select file)
                    ]
                    [ i [ class "fa fa-eye" ] []
                    ]
                , detailsToggleButton texts model file
                , div [ class "flex-grow flex flex-row justify-end" ]
                    [ a
                        [ classList
                            [ ( "ui right floated basic red icon button", True )
                            , ( "invisible", not settings.delete )
                            ]
                        , class S.deleteButton
                        , title texts.deleteFile
                        , href "#"
                        , onClick (ReqDelete file)
                        ]
                        [ i [ class "fa fa-trash" ] []
                        ]
                    ]
                ]
            ]
        , if Set.member file.id model.detailsOpen then
            div [ class "px-2 pb-2" ] [ fileDetails texts file ]

          else
            text ""
        ]


incompleteLabel : Texts -> ShareFile -> Html msg
incompleteLabel texts file =
    let
        perc =
            (toFloat file.storedSize / toFloat file.size * 100) |> round
    in
    div
        [ classList
            [ ( "hidden", file.size == file.storedSize )
            ]
        , class
            ("border label text-sm inline-flex  "
                ++ "border-red-600 text-red-700 "
                ++ "dark:bg-red-500 dark:bg-opacity-30 dark:text-red-400 dark:border-red-400"
            )
        ]
        [ i [ class "fa fa-bolt dark:text-red-400 mr-2" ] []
        , text
            (texts.fileIsIncomplete
                ++ String.fromInt perc
                ++ texts.tryUploadAgain
            )
        ]


detailsToggleButton : Texts -> Model -> ShareFile -> Html Msg
detailsToggleButton texts model file =
    let
        isOpen =
            Set.member file.id model.detailsOpen
    in
    a
        [ class S.secondaryBasicButton
        , class "text-xs"
        , title texts.toggleDetails
        , href "#"
        , onClick (ToggleDetails file)
        ]
        [ i
            [ class
                ("fa "
                    ++ (if isOpen then
                            "fa-chevron-up"

                        else
                            "fa-chevron-down"
                       )
                )
            ]
            []
        ]


fileDetails : Texts -> ShareFile -> Html Msg
fileDetails texts file =
    div
        [ class "flex flex-col text-sm space-y-1 px-3 py-2 rounded"
        , class "bg-gray-50 dark:bg-stone-700 dark:bg-opacity-40"
        ]
        [ div []
            [ span [ class "font-medium mr-2" ] [ text (texts.exactSize ++ ":") ]
            , text (Util.Size.exactBytes file.size)
            ]
        , div [ class "flex flex-row items-center flex-wrap" ]
            [ span [ class "font-medium mr-2" ] [ text (texts.checksumLabel ++ ":") ]
            , if file.checksum == "" then
                span [] [ text texts.checksumNotAvailable ]

              else
                span [ class "flex flex-row items-center space-x-2" ]
                    [ code [ class "break-all font-mono text-xs" ] [ text file.checksum ]
                    , button
                        [ class S.secondaryBasicButton
                        , class "file-checksum-copy text-xs"
                        , attribute "data-clipboard-text" file.checksum
                        , title texts.copyChecksum
                        , type_ "button"
                        ]
                        [ i [ class "fa fa-copy" ] [] ]
                    ]
            ]
        ]


previewDeferred : List String
previewDeferred =
    [ "video/", "audio/" ]


previewDirect : List String
previewDirect =
    [ "text/", "application/pdf" ]


previewFor : List String -> String -> Bool
previewFor mimeList mime =
    List.any (\x -> String.startsWith x mime) mimeList


previewPossible : String -> Bool
previewPossible mime =
    previewFor (previewDeferred ++ previewDirect ++ [ "image/" ]) mime


fileEmbed : Texts -> Settings -> Model -> ShareFile -> Html Msg
fileEmbed texts settings model file =
    let
        mime =
            file.mimetype
    in
    if previewFor previewDirect mime || Set.member file.id model.embedOn then
        iframe
            [ src (settings.baseUrl ++ file.id)
            , class "mx-auto min-h-preview dark:bg-stone-300 bg-gray-50"
            , if mime == "application/pdf" then
                sandbox "allow-scripts"

              else
                sandbox ""
            ]
            []

    else if previewFor previewDeferred mime then
        div [ class "min-h-preview flex flex-row items-center justify-center" ]
            [ a
                [ class "text-3xl"
                , class S.secondaryBasicButton
                , class "px-5 py-5 rounded-full"
                , onClick (EmbedFile file)
                , href "#"
                ]
                [ i [ class "fa fa-play " ] []
                ]
            ]

    else if String.startsWith "image/" mime then
        img
            [ src (settings.baseUrl ++ file.id)
            , class "mx-auto pt-1 max-h-52 "
            ]
            []

    else
        div [ class "px-8 py-8 text-center flex flex-col items-center justify-center min-h-preview" ]
            [ div [ class S.header3 ]
                [ i
                    [ class (fileIcon file)
                    , class "mr-2"
                    ]
                    []
                , text texts.previewNotSupported
                ]
            ]


modalSettings : Texts -> Comp.ConfirmModal.Settings Msg
modalSettings texts =
    Comp.ConfirmModal.defaultSettings
        DeleteConfirm
        DeleteCancel
        texts.yesNo.confirmButton
        texts.yesNo.cancelButton
        texts.yesNo.message


fileTable : Texts -> Settings -> Model -> List ShareFile -> Html Msg
fileTable texts settings model files =
    let
        yesNo =
            case model.requestDelete of
                Just _ ->
                    Comp.ConfirmModal.view (modalSettings texts)

                Nothing ->
                    span [] []
    in
    div [ class "md:relative" ]
        [ yesNo
        , table [ class S.tableMain ]
            [ Html.Keyed.node "tbody" [] <|
                List.concatMap
                    (\file ->
                        let
                            key =
                                file.id
                                    ++ (if Set.member file.id model.selectedFiles then
                                            ":1"

                                        else
                                            ":0"
                                       )

                            mainRow =
                                ( key, fileRow texts settings model file )
                        in
                        if Set.member file.id model.detailsOpen then
                            [ mainRow, ( file.id ++ ":details", fileDetailsRow texts file ) ]

                        else
                            [ mainRow ]
                    )
                    files
            ]
        ]


fileDetailsRow : Texts -> ShareFile -> Html Msg
fileDetailsRow texts file =
    tr [ class S.tableRow ]
        [ td [ colspan 3, class "px-3 pb-2" ] [ fileDetails texts file ] ]


fileRow : Texts -> Settings -> Model -> ShareFile -> Html Msg
fileRow texts { baseUrl, delete, zipBaseUrl } model file =
    let
        checked =
            isFileChecked model.selectedFiles file.id
    in
    tr
        [ id file.id
        , class S.tableRow
        ]
        [ td [ class "text-center py-2" ]
            [ i [ class ("text-2xl " ++ fileIcon file) ] []
            ]
        , td [ class "text-left w-full px-3 break-all sm:break-words" ]
            [ case zipBaseUrl of
                Just _ ->
                    input
                        [ type_ "checkbox"
                        , Html.Attributes.checked checked
                        , onCheck (\_ -> ToggleZipFile file.id)
                        , class S.checkboxInput
                        , class "mr-2"
                        ]
                        []

                Nothing ->
                    text ""
            , a
                [ title texts.downloadToDisk
                , download file.filename
                , href (baseUrl ++ file.id)
                , class S.link
                ]
                [ text file.filename
                ]
            , span [ class "text-sm font-mono" ]
                [ text " ("
                , toFloat file.size |> Util.Size.bytesReadable Util.Size.B |> text
                , text " · "
                , text (texts.dateTime file.created)
                , text ") "
                ]
            , incompleteLabel texts file
            ]
        , td [ class "" ]
            [ div [ class "text-right flex flex-row justify-end space-x-1 items-center" ]
                [ detailsToggleButton texts model file
                , a
                    [ classList
                        [ ( "hidden", not <| previewPossible file.mimetype )
                        ]
                    , class S.secondaryBasicButton
                    , class "text-xs"
                    , title texts.viewInBrowser
                    , href "#"
                    , onClick (Select file)
                    ]
                    [ i [ class "fa fa-eye" ] []
                    ]
                , a
                    [ classList
                        [ ( "hidden", not delete )
                        ]
                    , class S.deleteButton
                    , class "text-xs"
                    , title texts.deleteFile
                    , href "#"
                    , onClick (ReqDelete file)
                    ]
                    [ i [ class "fa fa-trash" ] []
                    ]
                ]
            ]
        ]


fileIcon : ShareFile -> String
fileIcon file =
    let
        mime =
            file.mimetype
    in
    if file.size /= file.storedSize then
        "text-red-500 fa fa-bolt"

    else if mime == "application/pdf" then
        "fa fa-file-pdf font-thin"

    else if mime == "application/zip" then
        "fa fa-file-archive font-thin"

    else if String.startsWith "image/" mime then
        "fa fa-file-image font-thin"

    else if String.startsWith "video/" mime then
        "fa fa-file-video font-thin"

    else if String.startsWith "audio/" mime then
        "fa fa-file-audio font-thin"

    else if String.startsWith "text/" mime then
        "fa fa-file-alt font-thin"

    else
        "fa fa-file font-thin"
