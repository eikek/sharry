module Comp.IntInput exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


type alias Model =
    { min : Maybe Int
    , max : Maybe Int
    , lastInput : String
    , isError : Bool
    }


type Msg
    = SetValue String


init : Maybe Int -> Maybe Int -> Model
init min max =
    { min = min
    , max = max
    , lastInput = ""
    , isError = False
    }


tooLow : Model -> Int -> Bool
tooLow model n =
    Maybe.map ((<) n) model.min
        |> Maybe.withDefault False


tooHigh : Model -> Int -> Bool
tooHigh model n =
    Maybe.map ((>) n) model.max
        |> Maybe.withDefault False


update : Msg -> Model -> ( Model, Maybe Int )
update msg model =
    case msg of
        SetValue str ->
            let
                m =
                    { model | lastInput = str }
            in
            case String.toInt str of
                Just n ->
                    if tooLow model n then
                        ( { m | isError = True }, Nothing )

                    else if tooHigh model n then
                        ( { m | isError = True }, Nothing )

                    else
                        ( { m | isError = False }, Just n )

                Nothing ->
                    ( { m | isError = True }
                    , Nothing
                    )


view : Maybe Int -> Model -> Html Msg
view nval model =
    input
        [ type_ "text"
        , Maybe.map String.fromInt nval
            |> Maybe.withDefault model.lastInput
            |> value
        , onInput SetValue
        ]
        []
