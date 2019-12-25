module Page.Info.Update exposing (update)

import Data.Flags exposing (Flags)
import Page.Info.Data exposing (Model, Msg(..))


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    ( model, Cmd.none )
