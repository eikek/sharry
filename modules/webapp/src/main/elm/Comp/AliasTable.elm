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
import Messages.AliasTable exposing (Texts)
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


view : Texts -> List AliasDetail -> Model -> Html Msg
view texts aliases model =
    table [ class "ui selectable padded table" ]
        [ thead []
            [ tr []
                [ th [] [ text texts.name ]
                , th [] [ text texts.enabled ]
                , th [] [ text texts.validity ]
                , th [] [ text texts.created ]
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
        [ onClick (Select alias_)
        , classList [ ( "active", isSelected model alias_ ) ]
        ]
        [ td [] [ text alias_.name ]
        , td []
            [ Util.Html.checkbox alias_.enabled
            ]
        , td []
            [ findValidityItemMillis texts.validityField alias_.validity
                |> Tuple.first
                |> text
            ]
        , td []
            [ texts.dateTime alias_.created
                |> text
            ]
        ]
