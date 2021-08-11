module Comp.ShareFileList exposing
    ( FileAction(..)
    , Model
    , Msg(..)
    , Settings
    , ViewMode(..)
    , init
    , previewPossible
    , reset
    , update
    , view
    )

import Api.Model.ShareFile exposing (ShareFile)
import Comp.ConfirmModal
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.ShareFileList exposing (Texts)
import Set exposing (Set)
import Styles as S
import Util.Size


type alias Model =
    { embedOn : Set String
    , requestDelete : Maybe ShareFile
    }


type Msg
    = Select ShareFile
    | EmbedFile ShareFile
    | ReqDelete ShareFile
    | DeleteConfirm
    | DeleteCancel


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
    }


reset : Model -> Model
reset model =
    { model | embedOn = Set.empty }


type alias Settings =
    { baseUrl : String
    , viewMode : ViewMode
    , delete : Bool
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



--- View


view : Texts -> Settings -> List ShareFile -> Model -> Html Msg
view texts settings files model =
    case settings.viewMode of
        ViewList ->
            fileTable texts settings model files

        ViewCard ->
            fileCards texts settings model files


fileCards : Texts -> Settings -> Model -> List ShareFile -> Html Msg
fileCards texts settings model files =
    div [ class "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4 gap-2" ] <|
        List.map (fileCard texts settings model) files


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
    in
    div
        [ class "relative hover:shadow-lg rounded flex flex-col break-words border border-gray-400 dark:border-warmgray-600 dark:hover:border-warmgray-500"
        , id file.id
        ]
        [ Comp.ConfirmModal.view deleteModal
        , div [ class "overflow-hidden block bg-gray-50 dark:bg-warmgray-700 dark:bg-opacity-40  border-gray-400 dark:hover:border-warmgray-500 rounded-t max-h-52" ]
            [ fileEmbed texts settings model file
            ]
        , div [ class "flex flex-col flex-grow px-2 my-2" ]
            [ div [ class "inline" ]
                [ a
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
            , class "mx-auto min-h-preview dark:bg-warmgray-300 bg-gray-50"
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
            [ tbody [] <|
                List.map (fileRow texts settings model) files
            ]
        ]


fileRow : Texts -> Settings -> Model -> ShareFile -> Html Msg
fileRow texts { baseUrl, delete } _ file =
    tr
        [ id file.id
        , class S.tableRow
        ]
        [ td [ class "text-center py-2" ]
            [ i [ class ("text-2xl " ++ fileIcon file) ] []
            ]
        , td [ class "text-left w-full px-3 break-all sm:break-words" ]
            [ a
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
                , text ") "
                ]
            , incompleteLabel texts file
            ]
        , td [ class "" ]
            [ div [ class "text-right flex flex-row justify-end space-x-1 items-center" ]
                [ a
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
