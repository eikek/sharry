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
import Comp.YesNoDimmer
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Set exposing (Set)
import Util.Size


type alias Model =
    { embedOn : Set String
    , requestDelete : Maybe ShareFile
    , yesNoModel : Comp.YesNoDimmer.Model
    }


type Msg
    = Select ShareFile
    | EmbedFile ShareFile
    | ReqDelete ShareFile
    | YesNoMsg Comp.YesNoDimmer.Msg


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
    , yesNoModel = Comp.YesNoDimmer.emptyModel
    }


dimmerSettings : Comp.YesNoDimmer.Settings
dimmerSettings =
    Comp.YesNoDimmer.defaultSettings


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
                , yesNoModel = Comp.YesNoDimmer.activate model.yesNoModel
              }
            , FileNone
            )

        YesNoMsg lmsg ->
            let
                ( ym, flag ) =
                    Comp.YesNoDimmer.update lmsg model.yesNoModel

                action =
                    case model.requestDelete of
                        Just sf ->
                            if flag then
                                FileDelete sf

                            else
                                FileNone

                        Nothing ->
                            FileNone
            in
            ( { model | yesNoModel = ym }, action )


view : Settings -> List ShareFile -> Model -> Html Msg
view settings files model =
    case settings.viewMode of
        ViewList ->
            fileTable settings model files

        ViewCard ->
            fileCards settings model files


fileCards : Settings -> Model -> List ShareFile -> Html Msg
fileCards settings model files =
    div [ class "ui centered cards" ] <|
        List.map (fileCard settings model) files


fileCard : Settings -> Model -> ShareFile -> Html Msg
fileCard settings model file =
    div [ class "ui card", id file.id ]
        [ Html.map YesNoMsg
            (Comp.YesNoDimmer.view2
                (model.requestDelete == Just file)
                dimmerSettings
                model.yesNoModel
            )
        , div [ class "image" ]
            [ fileEmbed settings model file
            ]
        , div [ class "content" ]
            [ text file.filename
            , text " ("
            , toFloat file.size |> Util.Size.bytesReadable Util.Size.B |> text
            , text ")"
            ]
        , div [ class "extra content" ]
            [ a
                [ class "ui basic icon button"
                , title "Download to disk"
                , download file.filename
                , href (settings.baseUrl ++ file.id)
                ]
                [ i [ class "download icon" ] []
                ]
            , a
                [ classList
                    [ ( "ui basic icon button", True )
                    , ( "invisible", not <| previewPossible file.mimetype )
                    ]
                , title "View in browser"
                , href "#"
                , onClick (Select file)
                ]
                [ i [ class "eye icon" ] []
                ]
            , incompleteLabel file
            , a
                [ classList
                    [ ( "ui right floated basic red icon button", True )
                    , ( "invisible", not settings.delete )
                    ]
                , title "Delete the file."
                , href "#"
                , onClick (ReqDelete file)
                ]
                [ i [ class "trash icon" ] []
                ]
            ]
        ]


incompleteLabel : ShareFile -> Html msg
incompleteLabel file =
    let
        perc =
            (toFloat file.storedSize / toFloat file.size * 100) |> round
    in
    div
        [ classList
            [ ( "ui red basic icon label", True )
            , ( "invisible", file.size == file.storedSize )
            ]
        ]
        [ i [ class "red bolt icon" ] []
        , text "The file is incomplete ("
        , String.fromInt perc |> text
        , text "%). Try uploading again."
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


fileEmbed : Settings -> Model -> ShareFile -> Html Msg
fileEmbed settings model file =
    let
        mime =
            file.mimetype
    in
    if previewFor previewDirect mime || Set.member file.id model.embedOn then
        embed
            [ src (settings.baseUrl ++ file.id)
            ]
            []

    else if previewFor previewDeferred mime then
        div [ class "ui embed" ]
            [ button
                [ type_ "button"
                , class "ui large secondary icon button"
                , onClick (EmbedFile file)
                ]
                [ i [ class "large play circle outline icon" ] []
                ]
            ]

    else if String.startsWith "image/" mime then
        img
            [ src (settings.baseUrl ++ file.id)
            , class "preview-image"
            ]
            []

    else
        div [ class "ui placeholder segment preview-image" ]
            [ div [ class "ui icon header" ]
                [ i [ class (fileIcon file) ] []
                , text "Preview not supported"
                ]
            ]


fileTable : Settings -> Model -> List ShareFile -> Html Msg
fileTable settings model files =
    let
        yesNo =
            case model.requestDelete of
                Just sf ->
                    Html.map YesNoMsg
                        (Comp.YesNoDimmer.view2
                            True
                            dimmerSettings
                            model.yesNoModel
                        )

                Nothing ->
                    span [] []
    in
    div []
        [ yesNo
        , table [ class "ui very basic table" ]
            [ tbody [] <|
                List.map (fileRow settings model) files
            ]
        ]


fileRow : Settings -> Model -> ShareFile -> Html Msg
fileRow { baseUrl, delete } model file =
    tr [ id file.id ]
        [ td [ class "collapsing" ]
            [ i [ class ("large " ++ fileIcon file) ] []
            ]
        , td []
            [ text file.filename
            , text " ("
            , toFloat file.size |> Util.Size.bytesReadable Util.Size.B |> text
            , text ") "
            , incompleteLabel file
            ]
        , td []
            [ a
                [ class "ui mini right floated basic icon button"
                , title "Download to disk"
                , href "#"
                , download file.filename
                , href (baseUrl ++ file.id)
                ]
                [ i [ class "download icon" ] []
                ]
            , a
                [ classList
                    [ ( "ui mini right floated basic icon button", True )
                    , ( "invisible", not <| previewPossible file.mimetype )
                    ]
                , title "View in browser"
                , href "#"
                , onClick (Select file)
                ]
                [ i [ class "eye icon" ] []
                ]
            , a
                [ classList
                    [ ( "ui mini red right floated basic icon button", True )
                    , ( "invisible", not delete )
                    ]
                , title "Delete file"
                , href "#"
                , onClick (ReqDelete file)
                ]
                [ i [ class "trash icon" ] []
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
        "red bolt icon"

    else if mime == "application/pdf" then
        "file pdf outline icon"

    else if mime == "application/zip" then
        "file archive outline icon"

    else if String.startsWith "image/" mime then
        "file image outline icon"

    else if String.startsWith "video/" mime then
        "file video outline icon"

    else if String.startsWith "audio/" mime then
        "file audio outline icon"

    else if String.startsWith "text/" mime then
        "file alternate outline icon"

    else
        "file outline icon"
