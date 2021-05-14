module Comp.MarkdownInput exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Comp.MenuBar as MB
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Markdown
import Messages.MarkdownInput exposing (Texts)
import Styles as S


type Display
    = Edit
    | Preview
    | Split


type alias Model =
    { display : Display
    , cheatSheetUrl : String
    }


init : Model
init =
    { display = Edit
    , cheatSheetUrl = "https://www.markdownguide.org/cheat-sheet"
    }


type Msg
    = SetText String
    | SetDisplay Display


update : String -> Msg -> Model -> ( Model, String )
update txt msg model =
    case msg of
        SetText str ->
            ( model, str )

        SetDisplay dsp ->
            ( { model | display = dsp }, txt )


view : Texts -> List ( String, Bool ) -> String -> Model -> Html Msg
view texts classes txt model =
    -- div [ class "flex flex-row text-sm" ]
    --    , a
    --        [ classList
    --            [ ( "ui link item", True )
    --            , ( "active", model.display == Split )
    --            ]
    --        , onClick (SetDisplay Split)
    --        , href "#"
    --        ]
    --        [ text texts.split
    --        ]
    --    , a
    --        [ class "ui right floated help-link link item"
    --        , target "_new"
    --        , href model.cheatSheetUrl
    --        ]
    --        [ i [ class "ui help icon" ] []
    --        , text texts.supportsMarkdown
    --        ]
    --    ]
    div
        [ classList classes ]
        [ MB.view
            { start =
                [ MB.ToggleButton
                    { active = model.display == Edit
                    , tagger = SetDisplay Edit
                    , label = texts.edit
                    , title = texts.edit
                    , icon = Just "fa fa-edit"
                    }
                , MB.ToggleButton
                    { active = model.display == Preview
                    , tagger = SetDisplay Preview
                    , label = texts.preview
                    , icon = Just "fa fa-eye"
                    , title = texts.preview
                    }
                , MB.ToggleButton
                    { active = model.display == Split
                    , tagger = SetDisplay Split
                    , label = texts.split
                    , icon = Just "fa fa-columns"
                    , title = texts.split
                    }
                ]
            , end =
                [ MB.CustomElement <|
                    a
                        [ class S.link
                        , class "my-auto"
                        , href model.cheatSheetUrl
                        ]
                        [ i [ class "fa fa-question-circle mr-2" ] []
                        , text texts.supportsMarkdown
                        ]
                ]
            , rootClasses = "text-sm"
            }
        , case model.display of
            Edit ->
                editDisplay txt

            Preview ->
                previewDisplay txt

            Split ->
                splitDisplay txt
        ]


editDisplay : String -> Html Msg
editDisplay txt =
    textarea
        [ class (String.replace S.formFocusRing "" S.textAreaInput)
        , class "w-full h-48 md:h-96 border-none min-h-full mt-1 focus:ring-0 focus:outline-none"
        , onInput SetText
        ]
        [ text txt ]


previewDisplay : String -> Html Msg
previewDisplay txt =
    Markdown.toHtml [ class "markdown-preview max-h-96 overflow-y-auto" ] txt


splitDisplay : String -> Html Msg
splitDisplay txt =
    div [ class "flex flex-col md:flex-row max-h-96 overflow-y-auto" ]
        [ div [ class "w-full md:w-1/2" ]
            [ editDisplay txt
            ]
        , div
            [ class "w-full md:w-1/2 border-t md:border-t-0 md:border-l pt-2 md:pl-1"
            , class "dark:border-warmgray-600"
            ]
            [ previewDisplay txt
            ]
        ]
