module Comp.MailForm exposing
    ( FormAction(..)
    , Model
    , Msg
    , init
    , initWith
    , update
    , view
    )

import Api.Model.MailTemplate exposing (MailTemplate)
import Api.Model.SimpleMail exposing (SimpleMail)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Messages.MailForm as T


type alias Model =
    { subject : String
    , body : String
    , receiver : String
    }


init : Model
init =
    { subject = ""
    , body = ""
    , receiver = ""
    }


initWith : MailTemplate -> Model
initWith tpl =
    { subject = tpl.subject
    , body = tpl.body
    , receiver = ""
    }


type Msg
    = SetSubject String
    | SetBody String
    | SetReceiver String
    | Cancel
    | Send


type FormAction
    = FormSend SimpleMail
    | FormCancel
    | FormNone


update : Msg -> Model -> ( Model, FormAction )
update msg model =
    case msg of
        SetSubject str ->
            ( { model | subject = str }, FormNone )

        SetBody str ->
            ( { model | body = str }, FormNone )

        SetReceiver str ->
            ( { model | receiver = str }, FormNone )

        Cancel ->
            ( model, FormCancel )

        Send ->
            let
                rec =
                    String.split "," model.receiver

                sm =
                    SimpleMail rec model.subject model.body
            in
            ( model, FormSend sm )


view : T.MailForm -> Model -> Html Msg
view texts model =
    div [ class "ui form" ]
        [ div [ class "field" ]
            [ label []
                [ text texts.receivers
                , span [ class "muted" ]
                    [ text texts.separateRecipientsByComma ]
                ]
            , input
                [ type_ "text"
                , onInput SetReceiver
                , value model.receiver
                ]
                []
            ]
        , div [ class "field" ]
            [ label [] [ text texts.subject ]
            , input
                [ type_ "text"
                , onInput SetSubject
                , value model.subject
                ]
                []
            ]
        , div [ class "field" ]
            [ label [] [ text texts.body ]
            , textarea [ onInput SetBody ]
                [ text model.body ]
            ]
        , button
            [ classList
                [ ( "ui primary button", True )
                , ( "disabled", model.receiver == "" )
                ]
            , onClick Send
            ]
            [ text texts.send
            ]
        , button
            [ class "ui secondary button"
            , onClick Cancel
            ]
            [ text texts.cancel
            ]
        ]
