module Comp.FixedDropdown exposing
    ( Item
    , Model
    , Msg
    , init
    , initMap
    , initString
    , initTuple
    , update
    , view
    , viewFloating
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.FixedDropdown exposing (Texts)


type alias Item a =
    { id : a
    , display : String
    , icon : Maybe String
    }


type alias Model a =
    { options : List (Item a)
    , menuOpen : Bool
    }


type Msg a
    = SelectItem (Item a)
    | ToggleMenu


init : List (Item a) -> Model a
init options =
    { options = options
    , menuOpen = False
    }


initString : List String -> Model String
initString strings =
    init <| List.map (\s -> Item s s Nothing) strings


initMap : (a -> String) -> List a -> Model a
initMap elToString els =
    init <| List.map (\a -> Item a (elToString a) Nothing) els


initTuple : List ( String, a ) -> Model a
initTuple tuples =
    let
        mkItem ( txt, id ) =
            Item id txt Nothing
    in
    init <| List.map mkItem tuples


update : Msg a -> Model a -> ( Model a, Maybe a )
update msg model =
    case msg of
        ToggleMenu ->
            ( { model | menuOpen = not model.menuOpen }, Nothing )

        SelectItem item ->
            ( model, Just item.id )


view : Maybe (Item a) -> Texts -> Model a -> Html (Msg a)
view =
    viewClass "ui selection dropdown"


viewFloating : Maybe (Item a) -> Texts -> Model a -> Html (Msg a)
viewFloating =
    viewClass "ui floating dropdown"


viewClass : String -> Maybe (Item a) -> Texts -> Model a -> Html (Msg a)
viewClass cls selected texts model =
    div
        [ classList
            [ ( cls, True )
            , ( "open", model.menuOpen )
            ]
        , onClick ToggleMenu
        ]
        [ div
            [ classList
                [ ( "default", selected == Nothing )
                , ( "text", True )
                ]
            ]
            (Maybe.map showSelected selected
                |> Maybe.withDefault [ text texts.select ]
            )
        , i [ class "dropdown icon" ] []
        , div
            [ classList
                [ ( "menu transition", True )
                , ( "hidden", not model.menuOpen )
                , ( "visible", model.menuOpen )
                ]
            ]
          <|
            List.map renderItems model.options
        ]


showSelected : Item a -> List (Html msg)
showSelected item =
    case item.icon of
        Just cls ->
            [ i [ class cls ] []
            , text item.display
            ]

        Nothing ->
            [ text item.display
            ]


renderItems : Item a -> Html (Msg a)
renderItems item =
    div [ class "item", onClick (SelectItem item) ]
        (showSelected item)
