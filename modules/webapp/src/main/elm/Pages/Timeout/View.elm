module Pages.Timeout.View exposing (..)

import Html exposing(Html, h1, div, text, a)
import Html.Attributes exposing (class, href)

import PageLocation as PL

view: Html msg
view =
    div [class "main ui grid container"]
        [
         div [class "sixteen wide column"]
             [
              h1 [class "ui header"]
                  [text "Session Timeout"]
             ,div [class "ui message"]
                 [
                  text "The session has timed out. Please "
                 ,a [href PL.loginPageHref][text "login"]
                 ,text " again."
                 ]
             ]
        ]
