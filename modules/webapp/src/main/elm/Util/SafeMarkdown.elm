module Util.SafeMarkdown exposing (toHtml)

import Html exposing (Attribute, Html)
import Markdown


{-| `elm-explorations/markdown` 1.0.0 embeds a version of marked whose
dangerous-URI check recognizes `&#xNN;` but not the browser-equivalent
uppercase `&#XNN;` form. Canonicalize that form before parsing so marked's
sanitizer sees and rejects javascript:, vbscript: and data: URLs.
-}
toHtml : List (Attribute msg) -> String -> Html msg
toHtml attributes source =
    source
        |> String.replace "&#X" "&#x"
        |> Markdown.toHtml attributes
