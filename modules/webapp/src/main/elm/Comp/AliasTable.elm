module Comp.AliasTable exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api.Model.AliasDetail exposing (AliasDetail)
import Data.ValidityOptions exposing (findValidityItemMillis)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.Duration
import Util.Html
import Util.Time


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


view : List AliasDetail -> Model -> Html Msg
view aliases model =
    table [ class "ui selectable padded table" ]
        [ thead []
            [ tr []
                [ th [] [ text "Name" ]
                , th [] [ text "Enabled" ]
                , th [] [ text "Validity" ]
                , th [] [ text "Created" ]
                ]
            ]
        , tbody []
            (List.map (viewTableLine model) aliases)
        ]


isSelected : Model -> AliasDetail -> Bool
isSelected model alias_ =
    Maybe.map .id model.selected
        |> Maybe.map ((==) alias_.id)
        |> Maybe.withDefault False


viewTableLine : Model -> AliasDetail -> Html Msg
viewTableLine model alias_ =
    tr
        [ onClick (Select alias_)
        , classList [ ( "active", isSelected model alias_ ) ]
        ]
        [ td [] [ text alias_.name ]
        , td []
            [ Util.Html.checkbox alias_.enabled
            ]
        , td []
            [ findValidityItemMillis alias_.validity
                |> Tuple.first
                |> text
            ]
        , td []
            [ Util.Time.formatIsoDateTime alias_.created
                |> text
            ]
        ]
