module Comp.AccountTable exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api.Model.AccountDetail exposing (AccountDetail)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.AccountTable exposing (Texts)
import Util.Html
import Util.Time


type alias Model =
    { selected : Maybe AccountDetail
    }


type Msg
    = Select AccountDetail


init : Model
init =
    { selected = Nothing
    }


update : Msg -> Model -> ( Model, Maybe AccountDetail )
update msg model =
    case msg of
        Select acc ->
            ( { model | selected = Just acc }, Just acc )


view : Texts -> List AccountDetail -> Model -> Html Msg
view texts accounts model =
    table [ class "ui selectable padded table" ]
        [ thead []
            [ tr []
                [ th [] [ text texts.login ]
                , th [] [ text texts.source ]
                , th [] [ text texts.state ]
                , th [] [ text texts.nrShares ]
                , th [] [ text texts.admin ]
                , th [] [ text texts.nrLogins ]
                , th [] [ text texts.lastLogin ]
                , th [] [ text texts.created ]
                ]
            ]
        , tbody []
            (List.map (viewTableLine model) accounts)
        ]


isSelected : Model -> AccountDetail -> Bool
isSelected model acc =
    Maybe.map .id model.selected
        |> Maybe.map ((==) acc.id)
        |> Maybe.withDefault False


viewTableLine : Model -> AccountDetail -> Html Msg
viewTableLine model acc =
    tr
        [ onClick (Select acc)
        , classList [ ( "active", isSelected model acc ) ]
        ]
        [ td [] [ text acc.login ]
        , td [] [ text acc.source ]
        , td [] [ text acc.state ]
        , td [] [ String.fromInt acc.shares |> text ]
        , td []
            [ Util.Html.checkbox acc.admin
            ]
        , td [] [ String.fromInt acc.loginCount |> text ]
        , td []
            [ Maybe.map Util.Time.formatDateTime acc.lastLogin
                |> Maybe.withDefault ""
                |> text
            ]
        , td []
            [ Util.Time.formatDateTime acc.created
                |> text
            ]
        ]
