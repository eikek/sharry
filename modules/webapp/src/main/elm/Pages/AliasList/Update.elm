module Pages.AliasList.Update exposing (..)

import Data exposing (defer)
import Pages.AliasList.Model exposing (..)
import Widgets.AliasList as AliasList

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        AliasListMsg msg ->
            let
                (m, c) = AliasList.update msg model.aliasList
            in
                {model | aliasList = m} ! [Cmd.map AliasListMsg c]
