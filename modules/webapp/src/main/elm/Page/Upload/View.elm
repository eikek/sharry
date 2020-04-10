module Page.Upload.View exposing (view)

import Comp.ShareTable
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Messages.UploadPage exposing (Texts)
import Page exposing (Page(..))
import Page.Upload.Data exposing (Model, Msg(..))


view : Texts -> Model -> Html Msg
view texts model =
    div
        [ classList
            [ ( "ui container upload-page", True )
            ]
        ]
        (viewList texts model)


viewList : Texts -> Model -> List (Html Msg)
viewList texts model =
    [ h1 [ class "ui dividing header" ]
        [ i [ class "ui share alternate icon" ] []
        , text texts.yourShares
        ]
    , searchArea texts model
    , Html.map ShareTableMsg
        (Comp.ShareTable.view texts.shareTable
            model.searchResult
            model.tableModel
        )
    ]


searchArea : Texts -> Model -> Html Msg
searchArea texts _ =
    div [ class "ui secondary menu" ]
        [ div [ class "ui container" ]
            [ div [ class "fitted-item" ]
                [ div [ class "ui icon input" ]
                    [ input
                        [ type_ "text"
                        , onInput SetQuery
                        , placeholder texts.search
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
                    [ text texts.newShare
                    ]
                ]
            ]
        ]
