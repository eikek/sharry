module Comp.Zoom exposing (FileUrl, view)

import Api.Model.ShareDetail exposing (ShareDetail)
import Api.Model.ShareFile exposing (ShareFile)
import Comp.ShareFileList exposing (ViewMode(..), previewPossible)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles as S
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
            [ ( "hidden", model.zoom == Nothing )
            ]
        , class S.dimmer
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
                [ div [ class "flex flex-row items-center justify-end w-full md:w-11/12" ]
                    [ a
                        [ href "#"
                        , classList
                            [ ( "disabled", prev == Nothing )
                            ]
                        , class S.primaryButtonPlain
                        , class "rounded-l"
                        , onClick (onSelect (Maybe.withDefault file prev))
                        ]
                        [ i [ class "fa fa-arrow-left" ] []
                        ]
                    , a
                        [ href "#"
                        , classList
                            [ ( "ui primary button", True )
                            , ( "disabled", next == Nothing )
                            ]
                        , class S.primaryButtonPlain
                        , onClick (onSelect (Maybe.withDefault file next))
                        ]
                        [ i [ class "fa fa-arrow-right" ] []
                        ]
                    , a
                        [ href "#"
                        , class S.secondaryButtonPlain
                        , class "rounded-r"
                        , onClick onQuit
                        ]
                        [ i [ class "fa fa-times" ] []
                        ]
                    ]
                , div
                    [ class "px-2 py-1 w-full md:w-11/12"
                    , class S.box
                    ]
                    [ div [ class "text-left text-sm font-mono" ]
                        [ text file.filename
                        , text " ("
                        , toFloat file.size |> Util.Size.bytesReadable Util.Size.B |> text
                        , text ")"
                        ]
                    ]
                , div
                    [ classList
                        [ ( "", isPdf file || isText file )
                        ]
                    , class " mx-auto flex flex-col bg-gray-800 dark:bg-warmgray-800 bg-opacity-90 h-screen-5/6 w-full md:w-11/12"
                    ]
                    [ div [ class "h-full" ]
                        [ filePreview fileUrl model file
                        ]
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
            , class "block max-h-full mx-auto"
            ]
            []

    else if isVideo file then
        video
            [ src url
            , class "block max-h-full mx-auto"
            , controls True
            , autoplay False
            ]
            []

    else if isPdf file then
        div [ class "dark:bg-warmgray-300 bg-white" ]
            [ iframe
                [ src url
                , sandbox "allow-scripts"
                , class "w-full"
                , attribute "width" "100%"
                , attribute "height" "100%"
                ]
                []
            ]

    else
        div [ class "dark:bg-warmgray-300 bg-white" ]
            [ iframe
                [ src url
                , sandbox ""
                , class "w-full"
                , attribute "width" "100%"
                , attribute "height" "100%"
                ]
                []
            ]


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
