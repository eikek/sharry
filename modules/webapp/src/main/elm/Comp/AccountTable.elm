module Comp.AccountTable exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api.Model.AccountDetail exposing (AccountDetail)
import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.AccountTable exposing (Texts)
import Styles as S
import Util.Html


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



--- View


view : Texts -> List AccountDetail -> Model -> Html Msg
view texts accounts model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [] []
                , th [ class "text-left" ] [ text texts.login ]
                , th [ class "text-left" ] [ text texts.source ]
                , th [ class "text-left" ] [ text texts.state ]
                , th [ class "text-center hidden sm:table-cell" ]
                    [ text texts.nrShares
                    ]
                , th [ class "text-center" ] [ text texts.admin ]
                , th [ class "text-center hidden sm:table-cell" ]
                    [ text texts.nrLogins
                    ]
                , th [ class "text-center hidden lg:table-cell" ] [ text texts.lastLogin ]
                , th [ class "text-center hidden lg:table-cell" ] [ text texts.created ]
                ]
            ]
        , tbody []
            (List.map (viewTableLine texts model) accounts)
        ]


isSelected : Model -> AccountDetail -> Bool
isSelected model acc =
    Maybe.map .id model.selected
        |> Maybe.map ((==) acc.id)
        |> Maybe.withDefault False


viewTableLine : Texts -> Model -> AccountDetail -> Html Msg
viewTableLine texts model acc =
    tr
        [ classList [ ( "active", isSelected model acc ) ]
        , class S.tableRow
        ]
        [ B.editLinkTableCell texts.edit (Select acc)
        , td [ class "text-left" ] [ text acc.login ]
        , td [ class "text-left" ] [ text acc.source ]
        , td [ class "text-left" ] [ text acc.state ]
        , td [ class "text-center hidden sm:table-cell" ]
            [ String.fromInt acc.shares |> text
            ]
        , td [ class "text-center" ]
            [ Util.Html.checkbox acc.admin
            ]
        , td [ class "text-center hidden sm:table-cell" ]
            [ String.fromInt acc.loginCount |> text
            ]
        , td [ class "text-center hidden lg:table-cell" ]
            [ Maybe.map texts.dateTime acc.lastLogin
                |> Maybe.withDefault ""
                |> text
            ]
        , td [ class "text-center hidden lg:table-cell" ]
            [ texts.dateTime acc.created
                |> text
            ]
        ]
