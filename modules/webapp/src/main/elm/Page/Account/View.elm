module Page.Account.View exposing (view)

import Api.Model.AccountDetail exposing (AccountDetail)
import Comp.AccountForm
import Comp.AccountTable
import Comp.MenuBar as MB
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.AccountPage exposing (Texts)
import Page exposing (Page(..))
import Page.Account.Data exposing (Model, Msg(..))
import Styles as S
import Util.Html


view : Maybe String -> Texts -> Model -> Html Msg
view id texts model =
    div
        [ class S.content
        , class "flex flex-col"
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


viewCreate : Texts -> Model -> List (Html Msg)
viewCreate texts model =
    [ h1 [ class S.header1 ]
        [ i [ class "fa fa-users mr-2" ] []
        , text texts.createAccountTitle
        ]
    , div [ class "mb-2" ]
        [ Html.map AccountFormMsg
            (Comp.AccountForm.view
                texts.accountForm
                model.formModel
            )
        ]
    , Maybe.map Util.Html.resultMsg model.saveResult
        |> Maybe.withDefault Util.Html.noElement
    ]


viewModify : Texts -> Model -> AccountDetail -> List (Html Msg)
viewModify texts model acc =
    [ h1 [ class S.header1 ]
        [ i [ class "fa fa-users mr-2" ] []
        , text acc.login
        , text " ("
        , text acc.source
        , text ")"
        , div [ class "text-sm opacity-70 font-mono" ]
            [ text acc.id
            ]
        ]
    , div [ class "mb-2" ]
        [ Html.map AccountFormMsg (Comp.AccountForm.view texts.accountForm model.formModel)
        ]
    , Maybe.map Util.Html.resultMsg model.saveResult
        |> Maybe.withDefault Util.Html.noElement
    ]


viewList : Texts -> Model -> List (Html Msg)
viewList texts model =
    [ h1 [ class S.header1 ]
        [ i [ class "fa fa-users mr-2" ] []
        , text texts.accounts
        ]
    , searchArea texts model
    , Html.map AccountTableMsg
        (Comp.AccountTable.view texts.accountTable
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
                { tagger = InitNewAccount
                , title = texts.newAccount
                , icon = Just "fa fa-plus"
                , label = texts.newAccount
                }
            ]
        , rootClasses = "mb-4"
        , sticky = True
        }
