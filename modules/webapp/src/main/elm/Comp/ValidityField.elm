module Comp.ValidityField exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Comp.FixedDropdown
import Data.Flags exposing (Flags)
import Data.ValidityOptions
    exposing
        ( findValidityItem
        , validityOptions
        )
import Data.ValidityValue exposing (ValidityValue)
import Html exposing (..)


type alias Model =
    Comp.FixedDropdown.Model ValidityValue


init : Flags -> Model
init flags =
    Comp.FixedDropdown.initTuple (validityOptions flags)


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


mkValidityItem : ( String, ValidityValue ) -> Comp.FixedDropdown.Item ValidityValue
mkValidityItem ( text, id ) =
    Comp.FixedDropdown.Item id text


view : ValidityValue -> Model -> Html Msg
view validity model =
    let
        value =
            findValidityItem validity
                |> mkValidityItem
    in
    Html.map ValidityMsg
        (Comp.FixedDropdown.view (Just value) model)
