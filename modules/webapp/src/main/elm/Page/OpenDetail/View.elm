module Page.OpenDetail.View exposing (view)

import Api
import Comp.MenuBar as MB
import Comp.PasswordInput
import Comp.ShareFileList exposing (ViewMode(..))
import Comp.Zoom
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onSubmit)
import Markdown
import Messages.DetailPage exposing (Texts)
import Page.OpenDetail.Data exposing (Model, Msg(..))
import Styles as S
import Util.Html
import Util.Share


view : Texts -> Flags -> Model -> Html Msg
view texts flags model =
    div
        [ class S.content
        , class "mb-3"
        ]
        [ zoomView flags model
        , passwordDialog texts model
        , descriptionView texts model
        , messageDiv model
        , middleMenu texts model
        , fileList texts flags model
        ]


zoomView : Flags -> Model -> Html Msg
zoomView flags model =
    Comp.Zoom.view (Api.fileOpenUrl flags (shareId model)) model SetZoom QuitZoom


passwordDialog : Texts -> Model -> Html Msg
passwordDialog texts model =
    div
        [ classList
            [ ( "hidden", not model.password.enabled )
            ]
        , class S.dimmer
        ]
        [ Html.form
            [ class "flex flex-col space-y-2"
            , onSubmit SubmitPassword
            , action "#"
            ]
            [ h2
                [ class S.header1
                , class "text-gray-100 flex flex-col items-center justify-center space-y-1"
                ]
                [ i [ class "fa fa-lock mr-2" ] []
                , text texts.passwordRequired
                ]
            , div [ class "flex flex-row" ]
                [ Html.map PasswordMsg
                    (Comp.PasswordInput.view
                        { placeholder = "" }
                        model.password.field
                        False
                        model.password.model
                    )
                , button
                    [ class S.primaryButton
                    , class "ml-2 block"
                    , href "#"
                    , type_ "submit"
                    , onClick SubmitPassword
                    ]
                    [ text texts.submit
                    ]
                ]
            , div
                [ classList
                    [ ( S.errorMessage, True )
                    , ( "hidden", not model.password.badPassword )
                    ]
                ]
                [ text texts.passwordInvalid
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
    div [ class "markdown-preview" ]
        [ Markdown.toHtml [] title
        , Markdown.toHtml [] desc
        ]


middleMenu : Texts -> Model -> Html Msg
middleMenu texts model =
    MB.view
        { start =
            []
        , end =
            [ MB.ToggleButton
                { tagger = SetFileView ViewList
                , active = model.fileView == ViewList
                , label = ""
                , icon = Just "fa fa-list"
                , title = texts.listView
                }
            , MB.ToggleButton
                { tagger = SetFileView ViewCard
                , active = model.fileView == ViewCard
                , label = ""
                , icon = Just "fa fa-th"
                , title = texts.cardView
                }
            ]
        , rootClasses = "my-2"
        , sticky = False
        }


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
