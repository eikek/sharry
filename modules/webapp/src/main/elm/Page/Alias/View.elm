module Page.Alias.View exposing (view)

import Api.Model.AliasDetail exposing (AliasDetail)
import Comp.AliasForm
import Comp.AliasTable
import Comp.MailSend
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Messages.AliasPage exposing (Texts)
import Page exposing (Page(..))
import Page.Alias.Data
    exposing
        ( Model
        , Msg(..)
        , clipboardData
        )
import QRCode
import Util.Html


view : Texts -> Flags -> Maybe String -> Model -> Html Msg
view texts flags id model =
    div
        [ classList
            [ ( "ui container alias-page", True )
            , ( "one column grid", model.selected /= Nothing )
            ]
        ]
    <|
        case model.selected of
            Just alias_ ->
                viewModify texts flags model alias_

            Nothing ->
                if id == Just "new" then
                    viewCreate texts model

                else
                    viewList texts model


viewCreate : Texts -> Model -> List (Html Msg)
viewCreate texts model =
    [ h1 [ class "ui dividing header" ]
        [ i [ class "ui upload icon" ] []
        , text texts.createNew
        ]
    , Html.map AliasFormMsg
        (Comp.AliasForm.view
            texts.aliasForm
            model.formModel
        )
    , Maybe.map Util.Html.resultMsg model.saveResult
        |> Maybe.withDefault Util.Html.noElement
    ]


viewModify : Texts -> Flags -> Model -> AliasDetail -> List (Html Msg)
viewModify texts flags model alias_ =
    [ div [ class "row" ]
        [ div [ class "column" ]
            [ h1 [ class "ui dividing header" ]
                [ i [ class "ui upload icon" ] []
                , text texts.aliasPage
                , text alias_.name
                ]
            , Html.map AliasFormMsg
                (Comp.AliasForm.view
                    texts.aliasForm
                    model.formModel
                )
            , Maybe.map Util.Html.resultMsg model.saveResult
                |> Maybe.withDefault Util.Html.noElement
            ]
        ]
    , div [ class "row" ]
        [ div [ class "column" ]
            [ shareText texts flags model alias_
            ]
        ]
    ]


viewList : Texts -> Model -> List (Html Msg)
viewList texts model =
    [ h1 [ class "ui dividing header" ]
        [ i [ class "ui users icon" ] []
        , text texts.aliasPages
        ]
    , searchArea texts model
    , Html.map AliasTableMsg
        (Comp.AliasTable.view
            texts.aliasTable
            model.searchResult
            model.tableModel
        )
    ]


searchArea : Texts -> Model -> Html Msg
searchArea texts _ =
    div [ class "ui secondary menu" ]
        [ div [ class "ui container" ]
            [ div [ class "fitted-item" ]
                [ div [ class "ui icon input" ]
                    [ input
                        [ type_ "text"
                        , onInput SetQuery
                        , placeholder texts.searchPlaceholder
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
                        [ text texts.newAliasPage
                        ]
                    ]
                ]
            ]
        ]


qrCodeView : Texts -> String -> Html msg
qrCodeView texts message =
    QRCode.fromString message
        |> Result.map (QRCode.toSvg [])
        |> Result.withDefault
            (Html.text texts.errorQrCode)


shareText : Texts -> Flags -> Model -> AliasDetail -> Html Msg
shareText texts flags model alias_ =
    let
        url =
            flags.config.baseUrl ++ Page.pageToString (OpenSharePage alias_.id)
    in
    div [ class "segments" ]
        [ div [ class "ui top attached header segment" ]
            [ text texts.shareThisLink
            ]
        , div [ class "ui attached message segment" ]
            [ text texts.aliasPageNowAt
            , pre [ class "url" ]
                [ code
                    [ id "alias-url"
                    ]
                    [ text url
                    ]
                ]
            , text texts.shareThisUrl
            ]
        , case model.mailForm of
            Just msm ->
                Html.map MailFormMsg
                    (Comp.MailSend.view
                        texts.mailSend
                        [ ( "ui bottom attached segment", True ) ]
                        msm
                    )

            Nothing ->
                shareInfo texts flags model url
        ]


shareInfo : Texts -> Flags -> Model -> String -> Html Msg
shareInfo texts flags model url =
    div [ class "ui bottom attached segment" ]
        [ div [ class "ui two column stackable center aligned grid" ]
            [ div [ class "ui vertical divider" ] [ text "Or" ]
            , div [ class "middle aligned row" ]
                [ div [ class "column" ]
                    [ qrCodeView texts url
                    ]
                , div [ class "column" ]
                    [ div
                        [ class "ui vertical buttons" ]
                        [ a
                            [ class "ui primary labeled icon button"
                            , Tuple.second clipboardData
                                |> String.dropLeft 1
                                |> id
                            , attribute "data-clipboard-target" "#alias-url"
                            , href "#"
                            ]
                            [ i [ class "copy icon" ] []
                            , text texts.copyLink
                            ]
                        , a
                            [ classList
                                [ ( "ui primary labeled icon button", True )
                                , ( "disabled", not flags.config.mailEnabled )
                                ]
                            , onClick InitMail
                            , href "#"
                            ]
                            [ i [ class "envelope icon" ] []
                            , text texts.sendEmail
                            ]
                        ]
                    ]
                ]
            ]
        ]
