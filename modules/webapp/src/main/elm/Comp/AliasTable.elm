module Comp.AliasTable exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api.Model.AliasDetail exposing (AliasDetail)
import Comp.Basic as B
import Data.ValidityOptions exposing (findValidityItemMillis)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.AliasTable exposing (Texts)
import Styles as S
import Util.Html


type alias Model =
    { selected : Maybe AliasDetail
    }


type Msg
    = Select AliasDetail


init : Model
init =
    { selected = Nothing
    }


update : Msg -> Model -> ( Model, Maybe AliasDetail )
update msg model =
    case msg of
        Select alias_ ->
            ( { model | selected = Just alias_ }, Just alias_ )



--- View


view : Texts -> List AliasDetail -> Model -> Html Msg
view texts aliases model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [] []
                , th [ class "text-center px-2 md:hidden" ] [ Util.Html.checkbox True ]
                , th [ class "text-center px-2 hidden md:table-cell" ] [ text texts.enabled ]
                , th [ class "text-left" ] [ text texts.name ]
                , th [ class "text-left hidden md:table-cell" ] [ text texts.validity ]
                , th [ class "text-left hidden md:table-cell" ] [ text texts.created ]
                ]
            ]
        , tbody []
            (List.map (viewTableLine texts model) aliases)
        ]


isSelected : Model -> AliasDetail -> Bool
isSelected model alias_ =
    Maybe.map .id model.selected
        |> Maybe.map ((==) alias_.id)
        |> Maybe.withDefault False


viewTableLine : Texts -> Model -> AliasDetail -> Html Msg
viewTableLine texts model alias_ =
    tr
        [ classList [ ( "active", isSelected model alias_ ) ]
        , class S.tableRow
        ]
        [ B.editLinkTableCell texts.edit (Select alias_)
        , td [ class "text-center py-4 md:py-2" ]
            [ Util.Html.checkbox alias_.enabled
            ]
        , td [ class "text-left py-4 md:py-2" ]
            [ text alias_.name ]
        , td [ class "text-left py-4 md:py-2 hidden md:table-cell" ]
            [ findValidityItemMillis texts.validityField alias_.validity
                |> Tuple.first
                |> text
            ]
        , td [ class "text-left hidden md:table-cell md:py-2" ]
            [ texts.dateTime alias_.created
                |> text
            ]
        ]
