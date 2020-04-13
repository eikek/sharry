module Comp.ShareTable exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api.Model.ShareListItem exposing (ShareListItem)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.ShareTable exposing (Texts)
import Util.Html
import Util.Size
import Util.String
import Util.Time


type alias Model =
    { selected : Maybe ShareListItem
    }


type Msg
    = Select ShareListItem


init : Model
init =
    { selected = Nothing
    }


update : Msg -> Model -> ( Model, Maybe ShareListItem )
update msg model =
    case msg of
        Select acc ->
            ( { model | selected = Just acc }, Just acc )


view : Texts -> List ShareListItem -> Model -> Html Msg
view texts accounts model =
    table [ class "ui selectable table" ]
        [ thead []
            [ tr []
                [ th [] [ text texts.nameId ]
                , th [] [ text texts.aliasLabel ]
                , th [ class "collapsing" ] [ text texts.maxViews ]
                , th [ class "collapsing" ] [ text texts.published ]
                , th [ class "collapsing" ] [ text texts.nFiles ]
                , th [ class "collapsing" ] [ text texts.size ]
                , th [ class "collapsing" ] [ text texts.created ]
                ]
            ]
        , tbody []
            (List.map (viewTableLine model) accounts)
        ]


isSelected : Model -> ShareListItem -> Bool
isSelected model item =
    Maybe.map .id model.selected
        |> Maybe.map ((==) item.id)
        |> Maybe.withDefault False


viewTableLine : Model -> ShareListItem -> Html Msg
viewTableLine model item =
    tr
        [ onClick (Select item)
        , classList [ ( "active", isSelected model item ) ]
        ]
        [ td [] [ Maybe.withDefault (Util.String.shorten 12 item.id) item.name |> text ]
        , td [] [ Maybe.withDefault "-" item.aliasName |> text ]
        , td [ class "collapsing" ] [ String.fromInt item.maxViews |> text ]
        , td [ class "collapsing" ]
            [ publishedState item
            ]
        , td [ class "collapsing" ]
            [ String.fromInt item.files |> text
            ]
        , td [ class "collapsing" ]
            [ toFloat item.size
                |> Util.Size.bytesReadable Util.Size.B
                |> text
            ]
        , td [ class "collapsing" ]
            [ Util.Time.formatDateTime item.created
                |> text
            ]
        ]


publishedState : ShareListItem -> Html Msg
publishedState item =
    case item.published of
        Just flag ->
            if flag then
                Util.Html.checkbox flag

            else
                i [ class "ui bolt icon" ] []

        Nothing ->
            Util.Html.checkboxUnchecked
