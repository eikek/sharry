module Page.OpenDetail.View exposing (view)

import Api
import Comp.PasswordInput
import Comp.ShareFileList exposing (ViewMode(..))
import Comp.Zoom
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Markdown
import Messages.DetailPage exposing (Texts)
import Page.OpenDetail.Data exposing (Model, Msg(..))
import Util.Html
import Util.Share


view : Texts -> Flags -> Model -> Html Msg
view texts flags model =
    div [ class "ui grid container detail-page" ]
        [ zoomView flags model
        , passwordDialog texts model
        , div [ class "row" ]
            [ div [ class "sixteen wide column" ]
                [ descriptionView texts model
                , messageDiv model
                , middleMenu texts model
                , fileList texts flags model
                ]
            ]
        ]


zoomView : Flags -> Model -> Html Msg
zoomView flags model =
    Comp.Zoom.view (Api.fileOpenUrl flags (shareId model)) model SetZoom QuitZoom


passwordDialog : Texts -> Model -> Html Msg
passwordDialog texts model =
    div
        [ classList
            [ ( "ui dimmer", True )
            , ( "active", model.password.enabled )
            ]
        ]
        [ div [ class "inline content" ]
            [ h2 [ class "ui inverted icon header" ]
                [ i [ class "lock icon" ] []
                , text texts.passwordRequired
                ]
            , div [ class "ui basic segment" ]
                [ div [ class "ui action input" ]
                    [ Html.map PasswordMsg
                        (Comp.PasswordInput.view
                            model.password.field
                            model.password.model
                        )
                    , a
                        [ class "ui primary button"
                        , href "#"
                        , onClick SubmitPassword
                        ]
                        [ text texts.submit
                        ]
                    ]
                , div
                    [ classList
                        [ ( "ui error message", True )
                        , ( "invisible hidden", not model.password.badPassword )
                        ]
                    ]
                    [ text texts.passwordInvalid
                    ]
                ]
            ]
        ]


messageDiv : Model -> Html Msg
messageDiv model =
    Util.Html.resultMsgMaybe model.message


descriptionView : Texts -> Model -> Html Msg
descriptionView texts model =
    let
        ( title, desc ) =
            Util.Share.splitDescription model.share texts.yourShare
    in
    div [ class "ui container share-description" ]
        [ Markdown.toHtml [] title
        , Markdown.toHtml [] desc
        ]


middleMenu : Texts -> Model -> Html Msg
middleMenu texts model =
    div
        [ class "ui menu"
        ]
        [ a
            [ classList
                [ ( "icon link item", True )
                , ( "active", model.fileView == ViewList )
                ]
            , href "#"
            , onClick (SetFileView ViewList)
            , title texts.listView
            ]
            [ i [ class "ui list icon" ] []
            ]
        , a
            [ classList
                [ ( "icon link item", True )
                , ( "active", model.fileView == ViewCard )
                ]
            , href "#"
            , onClick (SetFileView ViewCard)
            , title texts.cardView
            ]
            [ i [ class "th icon" ] []
            ]
        ]


fileList : Texts -> Flags -> Model -> Html Msg
fileList texts flags model =
    let
        sett =
            Comp.ShareFileList.Settings
                (Api.fileOpenUrl flags (shareId model) "")
                model.fileView
                False
    in
    Html.map FileListMsg <|
        Comp.ShareFileList.view texts.shareFileList
            sett
            model.share.files
            model.fileListModel


shareId : Model -> String
shareId model =
    Maybe.map .id model.share.publishInfo
        |> Maybe.withDefault ""
