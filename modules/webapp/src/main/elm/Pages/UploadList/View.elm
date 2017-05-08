module Pages.UploadList.View exposing (..)

import Html exposing (Html, div, h1, text)
import Html.Attributes exposing (class)

import Pages.UploadList.Model exposing (..)
import Widgets.UploadList as UploadList

view: Model -> Html Msg
view model =
    div [class "main ui grid container"]
        [
         div [class "sixteen wide column"]
             [
              h1 [class "header"] [text "Uploads"]
             ,(Html.map UploadListMsg (UploadList.view model.uploadList))
             ]
        ]
