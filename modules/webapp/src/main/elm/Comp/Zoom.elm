module Comp.Zoom exposing (FileUrl, view)

import Api
import Api.Model.ShareDetail exposing (ShareDetail)
import Api.Model.ShareFile exposing (ShareFile)
import Comp.ShareFileList exposing (ViewMode(..), previewPossible)
import Data.Flags exposing (Flags)
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
    div
        [ classList
            [ ( "ui dimmer", True )
            , ( "active", model.zoom /= Nothing )
            ]
        ]
        [ case model.zoom of
            Just file ->
                let
                    files =
                        List.filter (\f -> previewPossible f.mimetype) model.share.files

                    prev =
                        Util.List.findPrev (\e -> e.id == file.id) files

                    next =
                        Util.List.findNext (\e -> e.id == file.id) files
                in
                div [ class "ui container full-height" ]
                    [ div [ class "ui top attached centered mini menu" ]
                        [ button
                            [ type_ "button"
                            , class "ui button"
                            , onClick onQuit
                            ]
                            [ text "Back"
                            ]
                        , div [ class "text item" ]
                            [ text file.filename
                            , text " ("
                            , toFloat file.size |> Util.Size.bytesReadable Util.Size.B |> text
                            , text ")"
                            ]
                        , div [ class "right menu" ]
                            [ div [ class "ui buttons" ]
                                [ button
                                    [ type_ "button"
                                    , classList
                                        [ ( "ui icon button", True )
                                        , ( "disabled", prev == Nothing )
                                        ]
                                    , onClick (onSelect (Maybe.withDefault file prev))
                                    ]
                                    [ i [ class "arrow left icon" ] []
                                    ]
                                , button
                                    [ type_ "button"
                                    , classList
                                        [ ( "ui icon button", True )
                                        , ( "disabled", next == Nothing )
                                        ]
                                    , onClick (onSelect (Maybe.withDefault file next))
                                    ]
                                    [ i [ class "arrow right icon" ] []
                                    ]
                                ]
                            ]
                        ]
                    , filePreview fileUrl model file
                    ]

            Nothing ->
                span [] []
        ]


filePreview : FileUrl -> { m | share : ShareDetail, zoom : Maybe ShareFile } -> ShareFile -> Html msg
filePreview fileUrl model file =
    let
        url =
            fileUrl file.id
    in
    if String.startsWith "image/" file.mimetype then
        img
            [ src url
            , class "full-width"
            ]
            []

    else
        iframe
            [ src url
            , class "full-embed"
            , attribute "width" "100%"
            , attribute "height" "100%"
            ]
            []
