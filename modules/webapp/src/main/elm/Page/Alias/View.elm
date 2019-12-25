module Page.Alias.View exposing (view)

import Api.Model.AliasDetail exposing (AliasDetail)
import Comp.AliasForm
import Comp.AliasTable
import Comp.MailSend
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Page exposing (Page(..))
import Page.Alias.Data exposing (Model, Msg(..))
import QRCode
import Util.Html


view : Flags -> Maybe String -> Model -> Html Msg
view flags id model =
    div
        [ classList
            [ ( "ui container alias-page", True )
            , ( "text", id /= Nothing )
            , ( "one column grid", model.selected /= Nothing )
            ]
        ]
    <|
        case model.selected of
            Just alias_ ->
                viewModify flags model alias_

            Nothing ->
                if id == Just "new" then
                    viewCreate model

                else
                    viewList model


viewCreate : Model -> List (Html Msg)
viewCreate model =
    [ h1 [ class "ui dividing header" ]
        [ i [ class "ui upload icon" ] []
        , text "Create New Alias Page"
        ]
    , Html.map AliasFormMsg (Comp.AliasForm.view model.formModel)
    , Maybe.map Util.Html.resultMsg model.saveResult
        |> Maybe.withDefault Util.Html.noElement
    ]


viewModify : Flags -> Model -> AliasDetail -> List (Html Msg)
viewModify flags model alias_ =
    [ div [ class "row" ]
        [ div [ class "column" ]
            [ h1 [ class "ui dividing header" ]
                [ i [ class "ui upload icon" ] []
                , text "Alias Page: "
                , text alias_.name
                ]
            , Html.map AliasFormMsg (Comp.AliasForm.view model.formModel)
            , Maybe.map Util.Html.resultMsg model.saveResult
                |> Maybe.withDefault Util.Html.noElement
            ]
        ]
    , div [ class "row" ]
        [ div [ class "column" ]
            [ shareText flags model alias_
            ]
        ]
    ]


viewList : Model -> List (Html Msg)
viewList model =
    [ h1 [ class "ui dividing header" ]
        [ i [ class "ui users icon" ] []
        , text "Alias Pages"
        ]
    , searchArea model
    , Html.map AliasTableMsg (Comp.AliasTable.view model.searchResult model.tableModel)
    ]


searchArea : Model -> Html Msg
searchArea model =
    div [ class "ui secondary menu" ]
        [ div [ class "ui container" ]
            [ div [ class "fitted-item" ]
                [ div [ class "ui icon input" ]
                    [ input
                        [ type_ "text"
                        , onInput SetQuery
                        , placeholder "Search…"
                        ]
                        []
                    , i [ class "ui search icon" ]
                        []
                    ]
                ]
            , div [ class "right menu" ]
                [ div [ class "fitted-item" ]
                    [ a
                        [ class "ui primary button"
                        , Page.href (AliasPage (Just "new"))
                        ]
                        [ text "New Alias Page"
                        ]
                    ]
                ]
            ]
        ]


qrCodeView : String -> Html msg
qrCodeView message =
    QRCode.encode message
        |> Result.map QRCode.toSvg
        |> Result.withDefault
            (Html.text "Error while encoding to QRCode.")


shareText : Flags -> Model -> AliasDetail -> Html Msg
shareText flags model alias_ =
    let
        url =
            flags.config.baseUrl ++ Page.pageToString (OpenSharePage alias_.id)
    in
    div [ class "segments" ]
        [ div [ class "ui top attached header segment" ]
            [ text "Share this link"
            ]
        , div [ class "ui attached message segment" ]
            [ text "The alias page is now at: "
            , pre [ class "url" ]
                [ code []
                    [ text url
                    ]
                ]
            , text "You can share this URL with others to receive files from them."
            ]
        , case model.mailForm of
            Just msm ->
                Html.map MailFormMsg (Comp.MailSend.view [ ( "ui bottom attached segment", True ) ] msm)

            Nothing ->
                shareInfo flags model url
        ]


shareInfo : Flags -> Model -> String -> Html Msg
shareInfo flags model url =
    div [ class "ui bottom attached segment" ]
        [ div [ class "ui two column stackable center aligned grid" ]
            [ div [ class "ui vertical divider" ] [ text "Or" ]
            , div [ class "middle aligned row" ]
                [ div [ class "column" ]
                    [ qrCodeView url
                    ]
                , div [ class "column" ]
                    [ a
                        [ classList
                            [ ( "ui primary button", True )
                            , ( "disabled", not flags.config.mailEnabled )
                            ]
                        , onClick InitMail
                        , href "#"
                        ]
                        [ text "Send E-Mail"
                        ]
                    ]
                ]
            ]
        ]
