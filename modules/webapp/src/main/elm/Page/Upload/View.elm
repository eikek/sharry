module Page.Upload.View exposing (view)

import Comp.ShareTable
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Page exposing (Page(..))
import Page.Upload.Data exposing (Model, Msg(..))


view : Model -> Html Msg
view model =
    div
        [ classList
            [ ( "ui container upload-page", True )
            ]
        ]
        (viewList model)


viewList : Model -> List (Html Msg)
viewList model =
    [ h1 [ class "ui dividing header" ]
        [ i [ class "ui share alternate icon" ] []
        , text "Your Shares"
        ]
    , searchArea model
    , Html.map ShareTableMsg (Comp.ShareTable.view model.searchResult model.tableModel)
    ]


searchArea : Model -> Html Msg
searchArea model =
    div [ class "ui secondary menu" ]
        [ div [ class "ui container" ]
            [ div [ class "fitted-item" ]
                [ div [ class "ui icon input" ]
                    [ input
                        [ type_ "text"
                        , onInput SetQuery
                        , placeholder "Search…"
                        ]
                        []
                    , i [ class "ui search icon" ]
                        []
                    ]
                ]
            , div [ class "right menu" ]
                [ a
                    [ class "ui primary button"
                    , Page.href SharePage
                    ]
                    [ text "New Share"
                    ]
                ]
            ]
        ]
