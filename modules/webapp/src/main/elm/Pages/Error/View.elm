module Pages.Error.View exposing (..)

import Html exposing(Html, h1, div, text, a)
import Html.Attributes exposing (class, href)

import Pages.Error.Model exposing (..)

import PageLocation as PL

view: Model -> Html msg
view model =
    div [class "main ui grid container"]
        [
         div [class "sixteen wide column"]
             [
              h1 [class "ui header"]
                  [text "Error"]
             ,div [class "ui message"]
                 [
                  text model.message
                 ]
             ]
        ]
