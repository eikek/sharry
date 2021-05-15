module Comp.Dropzone2 exposing
    ( FileState(..)
    , Model
    , Msg
    , SelectedFiles
    , ViewSettings
    , init
    , mkViewSettings
    , update
    , view
    )

import Comp.Basic as B
import Comp.Progress
import Data.Percent
import Data.UploadDict exposing (UploadDict)
import Data.UploadState
import Dict
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D
import Messages.Dropzone2 exposing (Texts)
import Styles as S
import Util.Html exposing (onDragEnter, onDragLeave, onDragOver, onDropFiles, onFiles)
import Util.List
import Util.Size


type alias Model =
    { hover : Bool
    }


init : Model
init =
    { hover = False
    }


type Msg
    = DragEnter
    | DragLeave
    | GotFiles (List ( D.Value, File ))
    | DeleteFile Int


type alias SelectedFiles =
    List ( D.Value, File )


type FileState
    = Done
    | Failed
    | Uploading Int
    | Waiting


type alias ViewSettings =
    { files : SelectedFiles
    , active : Bool
    , fileState : Int -> FileState
    , allProgress : Int
    }


update : SelectedFiles -> Msg -> Model -> ( Model, Cmd Msg, SelectedFiles )
update current msg model =
    case msg of
        DragEnter ->
            ( { model | hover = True }, Cmd.none, current )

        DragLeave ->
            ( { model | hover = False }, Cmd.none, current )

        GotFiles list ->
            ( { model | hover = False }, Cmd.none, current ++ list )

        DeleteFile index ->
            ( model, Cmd.none, Util.List.remove index current )


mkViewSettings : Bool -> UploadDict -> ViewSettings
mkViewSettings active uploads =
    let
        getState index =
            Dict.get index uploads.uploads
                |> Maybe.map .state

        fileState index =
            case getState index of
                Just Data.UploadState.Complete ->
                    Done

                Just (Data.UploadState.Progress cur total) ->
                    Uploading (Data.Percent.mkPercent cur total)

                Just (Data.UploadState.Failed _) ->
                    Failed

                Nothing ->
                    Waiting
    in
    { files = uploads.selectedFiles
    , active = active
    , fileState = fileState
    , allProgress = Data.UploadDict.allProgress uploads
    }


view : Texts -> ViewSettings -> Model -> Html Msg
view texts sett model =
    let
        files =
            List.unzip sett.files
                |> Tuple.second

        allsize =
            List.map File.size files
                |> List.sum
                |> toFloat
                |> Util.Size.bytesReadable Util.Size.B
    in
    div [ class "flex flex-col" ]
        [ div
            [ classList
                [ ( "bg-opacity-100 bg-indigo-100 dark:bg-orange-800", model.hover )
                , ( "bg-indigo-100 bg-opacity-50 dark:bg-orange-900 dark:bg-opacity-50", not model.hover )
                , ( "disabled", not sett.active )
                ]
            , class "flex flex-col justify-center items-center py-2 md:py-12 border-0 border-t-2 border-indigo-500 dark:border-orange-500 h-24 md:h-auto"
            , onDragEnter DragEnter
            , onDragOver DragEnter
            , onDragLeave DragLeave
            , onDropFiles GotFiles
            ]
            [ div
                [ class S.header1
                , class "hidden md:inline-flex items-center"
                ]
                [ i [ class "fa fa-mouse-pointer" ] []
                , div [ class "ml-3" ]
                    [ text texts.dropHere
                    ]
                ]
            , case List.length files of
                0 ->
                    span [] []

                n ->
                    span [ class "py-1" ]
                        [ String.fromInt n |> text
                        , text texts.filesSelected
                        , text allsize
                        , text ")"
                        ]
            , B.horizontalDivider
                { label = texts.or
                , topCss = "w-2/3 mb-4 hidden md:inline-flex"
                , labelCss = "px-4 bg-gray-200 bg-opacity-50"
                , lineColor = "bg-gray-300 dark:bg-warmgray-600"
                }
            , div [ class "py-1" ]
                [ label [ class S.primaryBasicButton ]
                    [ i [ class "fa fa-folder-open mr-2" ] []
                    , text texts.selectFiles
                    , input
                        [ type_ "file"
                        , multiple True
                        , disabled <| not sett.active
                        , onFiles GotFiles
                        , class "hidden"
                        ]
                        []
                    ]
                ]
            ]
        , if files == [] then
            span [ class "hidden" ] []

          else
            Comp.Progress.progress2
                { parent = "h-2"
                , bar = "h-full"
                , label = "hidden"
                }
                sett.allProgress
        , div
            [ classList
                [ ( "hidden", files == [] )
                ]
            , class "flex flex-col divide-y dark:divide-warmgray-600"
            ]
            (List.indexedMap (renderFile sett) files)
        ]


renderFile : ViewSettings -> Int -> File -> Html Msg
renderFile sett index file =
    let
        size =
            File.size file
                |> toFloat
                |> Util.Size.bytesReadable Util.Size.B

        name =
            File.name file

        fileState =
            sett.fileState index

        icon =
            case fileState of
                Done ->
                    "fa fa-check text-green-500"

                Waiting ->
                    "fa fa-file font-thin"

                Uploading _ ->
                    "fa fa-spinner animate-spin"

                Failed ->
                    "fa fa-bolt text-red-500"

        percent =
            case fileState of
                Uploading p ->
                    p

                _ ->
                    0
    in
    div
        [ class ("file-" ++ String.fromInt index)
        , attribute "data-index" (String.fromInt index)
        , class "flex flex-row items-center"
        ]
        [ div [ class "text-center py-4 w-6" ]
            [ i [ class icon ] []
            ]
        , div [ class "flex-grow mx-2" ]
            [ if isUploading fileState then
                Comp.Progress.progress2
                    { parent = "h-6 border dark:border-warmgray-600 rounded"
                    , bar = "h-full rounded"
                    , label = "text-sm"
                    }
                    percent

              else
                span []
                    [ text name
                    ]
            ]
        , div [ class "text-right" ]
            [ span [ class "text-sm font-mono mr-2" ]
                [ text size
                ]
            , a
                [ classList
                    [ ( "hidden", not sett.active )
                    ]
                , class S.deleteButton
                , class "text-xs"
                , href "#"
                , onClick (DeleteFile index)
                ]
                [ i [ class "fa fa-trash" ] []
                ]
            ]
        ]


isUploading : FileState -> Bool
isUploading state =
    case state of
        Uploading _ ->
            True

        _ ->
            False
