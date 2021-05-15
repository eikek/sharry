module Comp.IntField exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Messages.IntField exposing (Texts)
import Styles as S


type alias Model =
    { min : Maybe Int
    , max : Maybe Int
    , error : Maybe (Texts -> String)
    , lastInput : String
    }


type Msg
    = SetValue String


init : Maybe Int -> Maybe Int -> Model
init min max =
    { min = min
    , max = max
    , error = Nothing
    , lastInput = ""
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
    let
        tooHighError texts =
            Maybe.withDefault 0 model.max
                |> String.fromInt
                |> (++) texts.mustBeLower

        tooLowError texts =
            Maybe.withDefault 0 model.min
                |> String.fromInt
                |> (++) texts.mustBeGreater
    in
    case msg of
        SetValue str ->
            let
                m =
                    { model | lastInput = str }
            in
            case String.toInt str of
                Just n ->
                    if tooLow model n then
                        ( { m | error = Just tooLowError }
                        , Nothing
                        )

                    else if tooHigh model n then
                        ( { m | error = Just tooHighError }
                        , Nothing
                        )

                    else
                        ( { m | error = Nothing }, Just n )

                Nothing ->
                    ( { m | error = Just (\texts -> texts.notANumber str) }
                    , Nothing
                    )


view : Maybe Int -> Texts -> String -> Model -> Html Msg
view nval texts labelText model =
    div
        [ class "mb-4"
        ]
        [ label [ class S.inputLabel ]
            [ text labelText ]
        , input
            [ type_ "text"
            , Maybe.map String.fromInt nval
                |> Maybe.withDefault model.lastInput
                |> value
            , onInput SetValue
            , class S.textInput
            , classList
                [ ( S.inputErrorBorder, model.error /= Nothing )
                ]
            ]
            []
        , div
            [ classList
                [ ( "text-red-500 label", True )
                , ( "hidden", model.error == Nothing )
                ]
            ]
            [ Maybe.map (\f -> f texts) model.error
                |> Maybe.withDefault ""
                |> text
            ]
        ]
