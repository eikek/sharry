module Page.Account.View exposing (view)

import Api.Model.AccountDetail exposing (AccountDetail)
import Api.Model.BasicResult exposing (BasicResult)
import Comp.AccountForm
import Comp.AccountTable
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Messages
import Page exposing (Page(..))
import Page.Account.Data exposing (Model, Msg(..))
import Util.Html


view : Maybe String -> Messages.Account -> Model -> Html Msg
view id texts model =
    div
        [ classList
            [ ( "ui container account-page", True )
            , ( "text", id /= Nothing )
            ]
        ]
    <|
        case model.selected of
            Just acc ->
                viewModify texts model acc

            Nothing ->
                if id == Just "new" then
                    viewCreate texts model

                else
                    viewList texts model


viewCreate : Messages.Account -> Model -> List (Html Msg)
viewCreate texts model =
    [ h1 [ class "ui dividing header" ]
        [ i [ class "ui user circle outline icon" ] []
        , text texts.createAccountTitle
        ]
    , div [ class "" ]
        [ Html.map AccountFormMsg (Comp.AccountForm.view texts.accountForm model.formModel)
        ]
    , Maybe.map Util.Html.resultMsg model.saveResult
        |> Maybe.withDefault Util.Html.noElement
    ]


viewModify : Messages.Account -> Model -> AccountDetail -> List (Html Msg)
viewModify texts model acc =
    [ h1 [ class "ui dividing header" ]
        [ i [ class "ui user circle icon" ] []
        , text acc.login
        ]
    , div [ class "" ]
        [ Html.map AccountFormMsg (Comp.AccountForm.view texts.accountForm model.formModel)
        ]
    , Maybe.map Util.Html.resultMsg model.saveResult
        |> Maybe.withDefault Util.Html.noElement
    ]


viewList : Messages.Account -> Model -> List (Html Msg)
viewList texts model =
    [ h1 [ class "ui dividing header" ]
        [ i [ class "ui users icon" ] []
        , text texts.accounts
        ]
    , searchArea texts model
    , Html.map AccountTableMsg
        (Comp.AccountTable.view texts.accountTable
            model.searchResult
            model.tableModel
        )
    ]


searchArea : Messages.Account -> Model -> Html Msg
searchArea texts model =
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
                        , Page.href (AccountPage (Just "new"))
                        ]
                        [ text texts.newAccount
                        ]
                    ]
                ]
            ]
        ]
