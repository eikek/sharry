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

import Data.UploadDict exposing (UploadDict)
import Data.UploadState
import Dict
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D
import Messages.Dropzone2 as T
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
    | Uploading
    | Waiting


type alias ViewSettings =
    { files : SelectedFiles
    , active : Bool
    , fileState : Int -> FileState
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

                Just (Data.UploadState.Progress _ _) ->
                    Uploading

                Just (Data.UploadState.Failed _) ->
                    Failed

                Nothing ->
                    Waiting
    in
    { files = uploads.selectedFiles
    , active = active
    , fileState = fileState
    }


view : T.Dropzone2 -> ViewSettings -> Model -> Html Msg
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
    div [ class "dropzone" ]
        [ div
            [ classList
                [ ( "ui top attached indicating progress", True )
                , ( "invisible", files == [] )
                ]
            , id "all-progress"
            ]
            [ div [ class "bar" ]
                []
            ]
        , div
            [ classList
                [ ( "ui placeholder segment", True )
                , ( "on-drop", model.hover )
                , ( "attached", files /= [] )
                , ( "disabled", not sett.active )
                ]
            , hijackOn "dragenter" (D.succeed DragEnter)
            , hijackOn "dragover" (D.succeed DragEnter)
            , hijackOn "dragleave" (D.succeed DragLeave)
            , hijackOn "drop" dropDecoder
            ]
            [ div [ class "ui icon header" ]
                [ i [ class "mouse pointer icon" ] []
                , div [ class "content" ]
                    [ text texts.dropHere
                    ]
                ]
            , case List.length files of
                0 ->
                    span [] []

                n ->
                    div [ class "inline" ]
                        [ String.fromInt n |> text
                        , text texts.filesSelected
                        , text allsize
                        , text ")"
                        ]
            , div [ class "ui horizontal divider" ]
                [ text texts.or
                ]
            , div [ class "custom-upload" ]
                [ label [ class "ui basic primary button" ]
                    [ i [ class "folder open icon" ] []
                    , text texts.selectFiles
                    , input
                        [ type_ "file"
                        , multiple True
                        , disabled <| not sett.active
                        , onFiles GotFiles
                        ]
                        []
                    ]
                ]
            ]
        , table
            [ classList
                [ ( "ui bottom attached table", True )
                , ( "invisible", files == [] )
                ]
            ]
            [ tbody []
                (List.indexedMap (renderFile sett) files)
            ]
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
                    "ui green check icon"

                Waiting ->
                    "ui file outline icon"

                Uploading ->
                    "ui loading spinner icon"

                Failed ->
                    "ui red bolt icon"
    in
    tr
        [ class ("file-" ++ String.fromInt index)
        , attribute "data-index" (String.fromInt index)
        ]
        [ td [ class "collapsing" ]
            [ i [ class icon ] []
            ]
        , td []
            [ div
                [ classList
                    [ ( "ui small indicating progress", True )
                    , ( "invisible", fileState /= Uploading )
                    ]
                , id ("file-progress-" ++ String.fromInt index)
                ]
                [ div [ class "bar" ] []
                , div [ class "label" ]
                    [ text name
                    ]
                ]
            , span
                [ classList
                    [ ( "invisible", fileState == Uploading )
                    ]
                ]
                [ text name
                ]
            ]
        , td [ class "collapsing" ]
            [ text size
            ]
        , td [ class "collapsing" ]
            [ a
                [ classList
                    [ ( "ui primary mini icon button", True )
                    , ( "disabled", not sett.active )
                    ]
                , href "#"
                , onClick (DeleteFile index)
                ]
                [ i [ class "ui trash icon" ] []
                ]
            ]
        ]


dropDecoder : D.Decoder Msg
dropDecoder =
    D.at [ "dataTransfer", "files" ] (D.list (attach File.decoder))
        |> D.map GotFiles


hijackOn : String -> D.Decoder msg -> Attribute msg
hijackOn event decoder =
    preventDefaultOn event (D.map hijack decoder)


hijack : msg -> ( msg, Bool )
hijack msg =
    ( msg, True )


onFiles : (List ( D.Value, File ) -> msg) -> Attribute msg
onFiles tomsg =
    let
        decmsg =
            D.at [ "target", "files" ] (D.list (attach File.decoder))
                |> D.map tomsg
    in
    hijackOn "change" decmsg


attach : D.Decoder a -> D.Decoder ( D.Value, a )
attach deca =
    let
        mkTuple v =
            D.map (Tuple.pair v) deca
    in
    D.andThen mkTuple D.value
