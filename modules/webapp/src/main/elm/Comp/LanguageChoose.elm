module Comp.LanguageChoose exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Comp.FixedDropdown exposing (Item)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages exposing (Language)
import Messages.FixedDropdown exposing (Texts)


type alias Model =
    Comp.FixedDropdown.Model Language


type alias Msg =
    Comp.FixedDropdown.Msg Language


init : Model
init =
    List.map mkLanguageItem Messages.allLanguages
        |> Comp.FixedDropdown.init


mkLanguageItem : Language -> Item Language
mkLanguageItem lang =
    let
        texts =
            Messages.get lang
    in
    Item lang texts.label (Just texts.flagIcon)


update : Msg -> Model -> ( Model, Maybe Language )
update msg model =
    Comp.FixedDropdown.update msg model


view : Texts -> Language -> Model -> Html Msg
view texts selected model =
    Comp.FixedDropdown.viewFloating
        (mkLanguageItem selected |> Just)
        texts
        model
