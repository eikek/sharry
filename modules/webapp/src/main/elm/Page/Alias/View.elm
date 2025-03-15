module Page.Alias.View exposing (view)

import Api.Model.AliasDetail exposing (AliasDetail)
import Comp.AliasForm
import Comp.AliasTable
import Comp.Basic as B
import Comp.MailSend
import Comp.MenuBar as MB
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.AliasPage exposing (Texts)
import Page exposing (Page(..))
import Page.Alias.Data
    exposing
        ( Model
        , Msg(..)
        , clipboardData
        )
import QRCode
import Styles as S
import Util.Html


view : Texts -> Flags -> Maybe String -> Model -> Html Msg
view texts flags id model =
    div
        [ class S.content
        , class "flex flex-col"
        ]
        (case model.selected of
            Just alias_ ->
                viewModify texts flags model alias_

            Nothing ->
                if id == Just "new" then
                    viewCreate flags texts model

                else
                    viewList flags texts model
        )


viewCreate : Flags -> Texts -> Model -> List (Html Msg)
viewCreate flags texts model =
    [ h1 [ class S.header1 ]
        [ i [ class "fa fa-upload mr-2" ] []
        , text texts.createNew
        ]
    , Html.map AliasFormMsg
        (Comp.AliasForm.view
            flags
            texts.aliasForm
            model.formModel
        )
    , Maybe.map Util.Html.resultMsg model.saveResult
        |> Maybe.withDefault Util.Html.noElement
    ]


viewModify : Texts -> Flags -> Model -> AliasDetail -> List (Html Msg)
viewModify texts flags model alias_ =
    let
        isOwner =
            Maybe.map .user flags.account
                |> Maybe.map ((==) alias_.owner)
                |> Maybe.withDefault False
    in
    [ div [ class "flex flex-col" ]
        [ h1 [ class S.header1 ]
            [ i [ class "fa fa-upload mr-2" ] []
            , text texts.aliasPage
            , text alias_.name
            , div [ class "text-sm opacity-75" ]
                [ text (texts.owner ++ ":")
                , span [ class "ml-1" ]
                    [ text alias_.owner
                    ]
                ]
            ]
        , if isOwner then
            Html.map AliasFormMsg
                (Comp.AliasForm.view flags
                    texts.aliasForm
                    model.formModel
                )

          else
            div [ class S.infoMessage ]
                [ text texts.notOwnerInfo
                ]
        , Maybe.map Util.Html.resultMsg model.saveResult
            |> Maybe.withDefault Util.Html.noElement
        , shareText texts flags model alias_
        ]
    ]


viewList : Flags -> Texts -> Model -> List (Html Msg)
viewList flags texts model =
    [ h1 [ class S.header1 ]
        [ i [ class "fa fa-dot-circle font-thin mr-2" ] []
        , text texts.aliasPages
        ]
    , searchArea texts model
    , Html.map AliasTableMsg
        (Comp.AliasTable.view flags
            texts.aliasTable
            model.searchResult
            model.tableModel
        )
    ]


searchArea : Texts -> Model -> Html Msg
searchArea texts model =
    MB.view
        { start =
            [ MB.TextInput
                { tagger = SetQuery
                , value = model.query
                , placeholder = texts.searchPlaceholder
                , icon = Just "fa fa-search"
                }
            ]
        , end =
            [ MB.PrimaryButton
                { tagger = InitNewAlias
                , title = texts.newAliasPage
                , icon = Just "fa fa-plus"
                , label = texts.newAliasPage
                }
            ]
        , rootClasses = "mb-4"
        , sticky = True
        }


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
    div [ class "mt-4" ]
        [ div [ class S.header2 ]
            [ i [ class "fa fa-share-alt mr-2" ] []
            , text texts.shareThisLink
            ]
        , div [ class S.message ]
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
                        [ ( "mt-2 px-2 py-2 " ++ S.box, True ) ]
                        msm
                    )

            Nothing ->
                shareInfo texts flags model url
        ]


shareInfo : Texts -> Flags -> Model -> String -> Html Msg
shareInfo texts flags model url =
    div [ class "flex flex-col md:flex-row py-2 h-full items-center justify-center" ]
        [ div [ class "md:w-2/3" ]
            [ div [ class "flex flex-col items-center  space-y-2 py-2" ]
                [ a
                    [ class S.primaryButton
                    , Tuple.second clipboardData
                        |> String.dropLeft 1
                        |> id
                    , attribute "data-clipboard-target" "#alias-url"
                    , href "#"
                    ]
                    [ i [ class "fa fa-copy mr-2" ] []
                    , text texts.copyLink
                    ]
                , B.primaryButton
                    { disabled = not flags.config.mailEnabled
                    , icon = "fa fa-envelope"
                    , label = texts.sendEmail
                    , handler = onClick InitMail
                    , attrs =
                        [ href "#"
                        ]
                    , responsive = False
                    }
                ]
            ]
        , div [ class "md:w-1/3 w-full " ]
            [ div
                [ class S.border
                , class S.styleQr
                ]
                [ qrCodeView texts url
                ]
            ]
        ]
