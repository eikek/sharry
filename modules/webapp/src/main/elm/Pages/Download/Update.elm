module Pages.Download.Update exposing (..)

import Pages.Download.Model exposing (..)
import Widgets.DownloadView as DownloadView

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        DownloadViewMsg msg ->
            let
                result = model.uploadViewModel
                       |> Maybe.map (DownloadView.update msg)
            in
                case result of
                    Just (m, c) ->
                        {model | uploadViewModel = Just m} ! [Cmd.map DownloadViewMsg c]
                    Nothing ->
                        model ! []
