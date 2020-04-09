module Page.Info.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Messages exposing (Messages)
import Page.Info.Data exposing (Model, Msg(..))
import Util.List


view : Int -> Messages -> Model -> Html Msg
view msg texts model =
    case Util.List.get model msg of
        Just m ->
            div [ class "info-page" ]
                [ div [ class "ui centered grid" ]
                    [ div [ class "row" ]
                        [ div [ class "eight wide column basic ui segment" ]
                            [ h1 [ class "ui header" ]
                                [ i [ class "ui info icon" ] []
                                , div [ class "content" ]
                                    [ text m.head
                                    ]
                                ]
                            , p []
                                [ text m.text
                                ]
                            ]
                        ]
                    ]
                ]

        Nothing ->
            div [] []
