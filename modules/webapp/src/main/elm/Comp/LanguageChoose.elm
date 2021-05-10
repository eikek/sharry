module Comp.LanguageChoose exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Comp.FixedDropdown
import Data.DropdownStyle as DS
import Html exposing (..)
import Html.Attributes exposing (..)
import Language exposing (Language)
import Messages
import Messages.FixedDropdown exposing (Texts)


type alias Model =
    Comp.FixedDropdown.Model Language


type alias Msg =
    Comp.FixedDropdown.Msg Language


init : Model
init =
    Comp.FixedDropdown.init Language.allLanguages


update : Msg -> Model -> ( Model, Maybe Language )
update msg model =
    Comp.FixedDropdown.update msg model


view : Texts -> Language -> Model -> Html Msg
view texts selected model =
    Comp.FixedDropdown.viewStyled
        { display = \lang -> Messages.get lang |> .label
        , icon = \lang -> Messages.get lang |> .flagIcon |> Just
        , selectPlaceholder = texts.select
        , style = DS.mainStyle
        }
        False
        (Just selected)
        model
