module Page.Account.View exposing (view)

import Api.Model.AccountDetail exposing (AccountDetail)
import Api.Model.BasicResult exposing (BasicResult)
import Comp.AccountForm
import Comp.AccountTable
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Messages exposing (Messages)
import Page exposing (Page(..))
import Page.Account.Data exposing (Model, Msg(..))
import Util.Html


view : Maybe String -> Messages -> Model -> Html Msg
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
                viewModify model acc

            Nothing ->
                if id == Just "new" then
                    viewCreate model

                else
                    viewList model


viewCreate : Model -> List (Html Msg)
viewCreate model =
    [ h1 [ class "ui dividing header" ]
        [ i [ class "ui user circle outline icon" ] []
        , text "Create a new internal account"
        ]
    , div [ class "" ]
        [ Html.map AccountFormMsg (Comp.AccountForm.view model.formModel)
        ]
    , Maybe.map Util.Html.resultMsg model.saveResult
        |> Maybe.withDefault Util.Html.noElement
    ]


viewModify : Model -> AccountDetail -> List (Html Msg)
viewModify model acc =
    [ h1 [ class "ui dividing header" ]
        [ i [ class "ui user circle icon" ] []
        , text acc.login
        ]
    , div [ class "" ]
        [ Html.map AccountFormMsg (Comp.AccountForm.view model.formModel)
        ]
    , Maybe.map Util.Html.resultMsg model.saveResult
        |> Maybe.withDefault Util.Html.noElement
    ]


viewList : Model -> List (Html Msg)
viewList model =
    [ h1 [ class "ui dividing header" ]
        [ i [ class "ui users icon" ] []
        , text "Accounts"
        ]
    , searchArea model
    , Html.map AccountTableMsg (Comp.AccountTable.view model.searchResult model.tableModel)
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
                        , Page.href (AccountPage (Just "new"))
                        ]
                        [ text "New Account"
                        ]
                    ]
                ]
            ]
        ]
