module Comp.Progress exposing (ProgressStyles, progress2)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)


type alias ProgressStyles =
    { parent : String
    , bar : String
    , label : String
    }


progress2 : ProgressStyles -> Int -> Html msg
progress2 css percent =
    div
        [ class " w-full relative"
        , class css.parent
        ]
        [ div
            [ class "transition-duration-300 bg-indigo-500 dark:bg-orange-500"
            , class "block text-xs text-center"
            , class css.bar
            , style "width" (String.fromInt percent ++ "%")
            ]
            []
        , div
            [ class "absolute left-1/2 top-0 font-semibold"
            , class css.label
            ]
            [ text (String.fromInt percent)
            , text "%"
            ]
        ]
