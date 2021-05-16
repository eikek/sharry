module Page.Info.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Page.Info.Data exposing (Model, Msg(..))
import Styles as S
import Util.List


view : Int -> Model -> Html Msg
view msg model =
    case Util.List.get model msg of
        Just m ->
            div
                [ class S.content
                ]
                [ h1 [ class S.header1 ]
                    [ i [ class "fa fa-info-circle mr-2" ] []
                    , text m.head
                    ]
                , p []
                    [ text m.text
                    ]
                ]

        Nothing ->
            div [] []
