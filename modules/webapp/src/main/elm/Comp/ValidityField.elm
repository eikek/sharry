module Comp.ValidityField exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Comp.FixedDropdown
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.ValidityOptions
    exposing
        ( findValidityItem
        , validityOptions
        )
import Data.ValidityValue exposing (ValidityValue)
import Html exposing (..)
import Messages.ValidityField exposing (Texts)


type alias Model =
    Comp.FixedDropdown.Model ValidityValue


init : Flags -> Model
init flags =
    Comp.FixedDropdown.init (validityOptions flags |> List.map Tuple.second)


type Msg
    = ValidityMsg (Comp.FixedDropdown.Msg ValidityValue)


update : Msg -> Model -> ( Model, Maybe ValidityValue )
update msg model =
    case msg of
        ValidityMsg lmsg ->
            let
                ( m, sel ) =
                    Comp.FixedDropdown.update lmsg model
            in
            ( m, sel )


view : Texts -> Flags -> ValidityValue -> Model -> Html Msg
view texts flags validity model =
    let
        value =
            findValidityItem texts flags validity |> Tuple.second

        dropdownCfg =
            { display = \vv -> findValidityItem texts flags vv |> Tuple.first
            , icon = \_ -> Nothing
            , style = DS.mainStyle
            , selectPlaceholder = texts.dropdown.select
            }
    in
    Html.map ValidityMsg
        (Comp.FixedDropdown.viewStyled dropdownCfg
            False
            (Just value)
            model
        )
