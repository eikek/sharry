module Pages.Manual.View exposing (..)

import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Markdown

import Pages.Manual.Model exposing (..)

markdownHtml: String -> Html msg
markdownHtml str =
    let
        defaultOpts = Markdown.defaultOptions
        markedOptions = {defaultOpts | sanitize = False, smartypants = True, githubFlavored = Just { tables = True, breaks = False}}
    in
        Markdown.toHtmlWith markedOptions [class "sharry-manual"] str


view: Model -> Html msg
view model =
    div [class "main ui text container"]
        [
         div [class "sixteen wide column"]
             [ markdownHtml model.manualPage
             ]
        ]
