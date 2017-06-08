module Widgets.MarkdownEditor exposing (..)

import Html exposing (Html, div, textarea)
import Html.Attributes exposing (class, value, style)
import Html.Events exposing (onInput)

import Data

type alias Model =
    {text: String
    }

emptyModel: Model
emptyModel = Model ""

initModel: String -> Model
initModel str =
    Model str

type Msg
    = SetText String

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        SetText str ->
            {model | text = str} ! []


view: Model -> Html Msg
view model =
    div [class "ui stackable two column grid"]
        [
         div [class "column"]
             [textarea [onInput SetText, class "sharry-md-edit", value model.text][]
             ]
        ,div [class "column"]
            [Data.markdownHtml model.text
            ]
        ]
