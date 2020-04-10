module Page.Home.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.HomePage exposing (Texts)
import Page exposing (Page(..))
import Page.Home.Data exposing (Model)


view : Texts -> Model -> Html msg
view texts model =
    div [ class "ui container home-page" ]
        [ div [ class "ui red raised placeholder segment" ]
            [ h1 [ class "ui icon header" ]
                [ i [ class "ui share alternate square icon" ] []
                , text "Share files with others"
                ]
            , div [ class "inline" ]
                [ a
                    [ class "ui large primary button"
                    , Page.href SharePage
                    ]
                    [ text texts.createShare
                    ]
                , a
                    [ class "ui large secondary button"
                    , Page.href UploadPage
                    ]
                    [ text texts.viewShares
                    ]
                ]
            ]
        , div [ class "documentation-link" ]
            [ a
                [ class "link"
                , href "https://eikek.github.io/sharry/doc/webapp"
                , target "_blank"
                ]
                [ i [ class "external alternate icon" ] []
                , text texts.documentation
                ]
            ]
        ]
