module Comp.LanguageChoose exposing (linkList)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages exposing (Language)


linkList : (Language -> msg) -> Html msg
linkList tagger =
    let
        renderFlag lang =
            a
                [ class "item"
                , href "#"
                , onClick (tagger lang)
                , title (Messages.get lang |> .label)
                ]
                [ i [ Messages.get lang |> .flagIcon |> class ] []
                ]
    in
    div [ class "ui mini horizontal divided link list" ]
        (List.map renderFlag Messages.allLanguages)
