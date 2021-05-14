module Comp.ShareTable exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api.Model.ShareListItem exposing (ShareListItem)
import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.ShareTable exposing (Texts)
import Styles as S
import Util.Html
import Util.Size
import Util.String


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
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [] []
                , th [ class "text-left" ] [ text texts.nameId ]
                , th [ class "text-left hidden sm:table-cell" ] [ text texts.aliasLabel ]
                , th [ class "text-center hidden lg:table-cell" ] [ text texts.maxViews ]
                , th [ class "text-center" ] [ text texts.published ]
                , th [ class "text-center" ] [ text texts.nFiles ]
                , th [ class "text-center hidden lg:table-cell" ] [ text texts.size ]
                , th [ class "text-center hidden lg:table-cell" ] [ text texts.created ]
                ]
            ]
        , tbody []
            (List.map (viewTableLine texts model) accounts)
        ]


isSelected : Model -> ShareListItem -> Bool
isSelected model item =
    Maybe.map .id model.selected
        |> Maybe.map ((==) item.id)
        |> Maybe.withDefault False


viewTableLine : Texts -> Model -> ShareListItem -> Html Msg
viewTableLine texts model item =
    tr
        [ classList
            [ ( "active", isSelected model item )
            ]
        , class S.tableRow
        ]
        [ B.editLinkTableCell "Edit" (Select item)
        , td [ class "text-left" ]
            [ Maybe.withDefault (Util.String.shorten 12 item.id) item.name
                |> text
            ]
        , td [ class "text-left hidden sm:table-cell" ]
            [ Maybe.withDefault "-" item.aliasName
                |> text
            ]
        , td [ class "text-center hidden lg:table-cell" ]
            [ String.fromInt item.maxViews
                |> text
            ]
        , td [ class "text-center" ]
            [ publishedState item
            ]
        , td [ class "text-center" ]
            [ String.fromInt item.files |> text
            ]
        , td [ class "text-center hidden lg:table-cell" ]
            [ toFloat item.size
                |> Util.Size.bytesReadable Util.Size.B
                |> text
            ]
        , td [ class "text-center hidden lg:table-cell" ]
            [ texts.dateTime item.created |> text
            ]
        ]


publishedState : ShareListItem -> Html Msg
publishedState item =
    case item.published of
        Just flag ->
            if flag then
                i [ class S.published ] []

            else
                i [ class S.publishError ] []

        Nothing ->
            i [ class S.unpublished ] []
