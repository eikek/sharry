module Pages.AliasList.View exposing (..)

import Html exposing (Html, div, text, h1, p)
import Html.Attributes exposing (class)

import Widgets.AliasList as AliasList
import Pages.AliasList.Model exposing (..)

view: Model -> Html Msg
view model =
    div [class "main ui grid container"]
        [
         div [class "sixteen wide column"]
             [
              h1 [class "header"] [text "Aliases"]
             ,p[][text "Aliases are pages where other people can upload files for you."]
             ,(Html.map AliasListMsg (AliasList.view model.aliasList))
             ]
        ]
