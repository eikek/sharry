module Pages.Download.View exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class)

import Widgets.DownloadView as DownloadView
import Pages.Download.Model exposing (..)

view: Model -> Html Msg
view model =
    case model.uploadViewModel of
        Just m ->
            div [class "main ui grid container"]
                (List.map (Html.map DownloadViewMsg) (DownloadView.view m))

        Nothing ->
            div[][text "You must specify the download id"]
