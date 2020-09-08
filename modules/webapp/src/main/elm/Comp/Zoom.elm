module Comp.Zoom exposing (FileUrl, view)

import Api.Model.ShareDetail exposing (ShareDetail)
import Api.Model.ShareFile exposing (ShareFile)
import Comp.ShareFileList exposing (ViewMode(..), previewPossible)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.List
import Util.Size


type alias FileUrl =
    String -> String


view :
    FileUrl
    -> { m | share : ShareDetail, zoom : Maybe ShareFile }
    -> (ShareFile -> msg)
    -> msg
    -> Html msg
view fileUrl model onSelect onQuit =
    let
        sortedFiles =
            List.sortBy .filename model.share.files
    in
    div
        [ classList
            [ ( "ui dimmer", True )
            , ( "active", model.zoom /= Nothing )
            ]
        ]
    <|
        case model.zoom of
            Just file ->
                let
                    files =
                        List.filter (\f -> previewPossible f.mimetype) sortedFiles

                    prev =
                        Util.List.findPrev (\e -> e.id == file.id) files

                    next =
                        Util.List.findNext (\e -> e.id == file.id) files
                in
                [ div [ class "zoom-controls" ]
                    [ div [ class "ui buttons" ]
                        [ button
                            [ type_ "button"
                            , classList
                                [ ( "ui primary button", True )
                                , ( "disabled", prev == Nothing )
                                ]
                            , onClick (onSelect (Maybe.withDefault file prev))
                            ]
                            [ i [ class "arrow left icon" ] []
                            ]
                        , button
                            [ type_ "button"
                            , class "ui secondary icon button"
                            , onClick onQuit
                            ]
                            [ i [ class "close icon" ] []
                            ]
                        , button
                            [ type_ "button"
                            , classList
                                [ ( "ui primary button", True )
                                , ( "disabled", next == Nothing )
                                ]
                            , onClick (onSelect (Maybe.withDefault file next))
                            ]
                            [ i [ class "arrow right icon" ] []
                            ]
                        ]
                    ]
                , div
                    [ classList
                        [ ( "ui container", True )
                        , ( "white zoom-container", True )
                        , ( "fixed-height", isPdf file || isText file )
                        ]
                    ]
                    [ div [ class "ui top attached centered inverted mini menu" ]
                        [ div [ class "text item" ]
                            [ text file.filename
                            , text " ("
                            , toFloat file.size |> Util.Size.bytesReadable Util.Size.B |> text
                            , text ")"
                            ]
                        , div [ class "right menu" ]
                            [ a
                                [ class "item"
                                , href "#"
                                , onClick onQuit
                                ]
                                [ i [ class "close icon" ] []
                                ]
                            ]
                        ]
                    , filePreview fileUrl model file
                    ]
                ]

            Nothing ->
                []


filePreview : FileUrl -> { m | share : ShareDetail, zoom : Maybe ShareFile } -> ShareFile -> Html msg
filePreview fileUrl _ file =
    let
        url =
            fileUrl file.id
    in
    if isImage file then
        img
            [ src url
            , class "zoom-image"
            ]
            []

    else if isVideo file then
        video
            [ src url
            , class "zoom-video"
            , controls True
            , autoplay False
            ]
            []

    else
        iframe
            [ src url
            , class "zoom-iframe"
            , attribute "width" "100%"
            , attribute "height" "100%"
            ]
            []


isVideo : ShareFile -> Bool
isVideo file =
    String.startsWith "video/" file.mimetype


isImage : ShareFile -> Bool
isImage file =
    String.startsWith "image/" file.mimetype


isText : ShareFile -> Bool
isText file =
    String.startsWith "text/" file.mimetype


isPdf : ShareFile -> Bool
isPdf file =
    "application/pdf" == file.mimetype
