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
import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Messages.MailForm exposing (Texts)
import Styles as S


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



--- View


view : Texts -> Model -> Html Msg
view texts model =
    div [ class "flex flex-col" ]
        [ div [ class "mb-4" ]
            [ label
                [ class S.inputLabel
                ]
                [ text texts.receivers
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , class S.textInput
                , onInput SetReceiver
                , value model.receiver
                ]
                []
            , span [ class "text-sm opacity-70" ]
                [ text texts.separateRecipientsByComma ]
            ]
        , div [ class "mb-4" ]
            [ label
                [ class S.inputLabel
                ]
                [ text texts.subject
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetSubject
                , value model.subject
                , class S.textInput
                ]
                []
            ]
        , div [ class "mb-4" ]
            [ label
                [ class S.inputLabel
                ]
                [ text texts.body
                , B.inputRequired
                ]
            , textarea
                [ onInput SetBody
                , class S.textAreaInput
                , class "h-48"
                , value model.body
                ]
                []
            ]
        , div [ class "flex flex-row space-x-2" ]
            [ B.primaryButton
                { disabled =
                    String.isEmpty model.receiver
                        || String.isEmpty model.subject
                        || String.isEmpty model.body
                , icon = "fa fa-paper-plane font-thin"
                , label = texts.send
                , handler = onClick Send
                , attrs =
                    [ href "#"
                    ]
                , responsive = False
                }
            , B.secondaryButton
                { disabled = False
                , handler = onClick Cancel
                , label = texts.cancel
                , icon = ""
                , attrs =
                    [ href "#"
                    ]
                , responsive = False
                }
            ]
        ]
