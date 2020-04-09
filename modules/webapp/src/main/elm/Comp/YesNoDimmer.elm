module Comp.YesNoDimmer exposing
    ( Model
    , Msg
    , Settings
    , activate
    , defaultSettings
    , disable
    , emptyModel
    , update
    , view
    , view2
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.YesNoDimmer as T


type alias Model =
    { active : Bool
    }


emptyModel : Model
emptyModel =
    { active = False
    }


type Msg
    = Activate
    | Disable
    | ConfirmDelete


type alias Settings =
    { message : String
    , headerIcon : String
    , headerClass : String
    , confirmButton : String
    , cancelButton : String
    , invertedDimmer : Bool
    }


defaultSettings : T.YesNoDimmer -> Settings
defaultSettings texts =
    { message = texts.message
    , headerIcon = "exclamation icon"
    , headerClass = "ui inverted icon header"
    , confirmButton = texts.confirmButton
    , cancelButton = texts.cancelButton
    , invertedDimmer = False
    }


activate : Model -> Model
activate model =
    update Activate model
        |> Tuple.first


disable : Model -> Model
disable model =
    update Disable model
        |> Tuple.first


update : Msg -> Model -> ( Model, Bool )
update msg model =
    case msg of
        Activate ->
            ( { model | active = True }, False )

        Disable ->
            ( { model | active = False }, False )

        ConfirmDelete ->
            ( { model | active = False }, True )


view : T.YesNoDimmer -> Model -> Html Msg
view texts model =
    view2 True (defaultSettings texts) model


view2 : Bool -> Settings -> Model -> Html Msg
view2 active settings model =
    div
        [ classList
            [ ( "ui dimmer", True )
            , ( "inverted", settings.invertedDimmer )
            , ( "active", active && model.active )
            ]
        ]
        [ div [ class "content" ]
            [ h3 [ class settings.headerClass ]
                [ if settings.headerIcon == "" then
                    span [] []

                  else
                    i [ class settings.headerIcon ] []
                , text settings.message
                ]
            ]
        , div [ class "content" ]
            [ div [ class "ui buttons" ]
                [ a [ class "ui primary button", onClick ConfirmDelete, href "" ]
                    [ text settings.confirmButton
                    ]
                , div [ class "or" ] []
                , a [ class "ui secondary button", onClick Disable, href "" ]
                    [ text settings.cancelButton
                    ]
                ]
            ]
        ]
