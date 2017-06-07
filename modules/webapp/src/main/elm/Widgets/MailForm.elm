module Widgets.MailForm exposing (..)

import Http
import Regex
import Html exposing (Html, div, text, a, form, input, textarea, h3, label)
import Html.Attributes exposing (class, classList, type_, rows, placeholder, value, name)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Json.Encode as Encode

import Data exposing (RemoteUrls)
import PageLocation as PL

type alias Model =
    {urls: RemoteUrls
    ,text: String
    ,subject: String
    ,recipients: String
    ,tos: List String
    ,sending: Bool
    ,errorMessage: List String
    ,successMessage: List String
    }

type alias Template =
    {subject: String
    ,text: String
    }

decodeTemplate: Decode.Decoder Template
decodeTemplate =
    Decode.map2 Template
        (Decode.field "subject" Decode.string)
        (Decode.field "text" Decode.string)

makeModel: RemoteUrls -> Model
makeModel urls =
    Model urls "" "" "" [] False [] []

isSuccessfulSend: Model -> Bool
isSuccessfulSend model =
    List.isEmpty model.errorMessage && List.isEmpty model.successMessage |> not

type alias SendResult =
    {message: String
    ,success: List (String)
    ,failed: List (String)
    }

decodeResult: Decode.Decoder SendResult
decodeResult =
    Decode.map3 SendResult
        (Decode.field "message" Decode.string)
        (Decode.field "success" (Decode.list Decode.string))
        (Decode.field "failed" (Decode.list Decode.string))

encodeMail: Model -> Encode.Value
encodeMail model =
    Encode.object
        [("to", Encode.list (List.map Encode.string model.tos))
        ,("subject", Encode.string model.subject)
        ,("text", Encode.string model.text)]


type Msg
    = TemplateResult (Result Http.Error Template)
    | SetRecipient String
    | SetText String
    | SetSubject String
    | SendMail
    | MailSendResult (Result Http.Error SendResult)

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        TemplateResult (Ok t) ->
            {model
                | subject = t.subject
                , text = t.text
            } ! []

        TemplateResult (Err error) ->
            {model | errorMessage = [Data.errorMessage error]} ! [PL.timeoutCmd error]

        SetText text ->
            let
                m = {model | text = text}
            in
                {m | errorMessage = validate m, successMessage = []} ! []

        SetSubject text ->
            let
                m = {model | subject = text}
            in
                {m | errorMessage = validate m, successMessage = []} ! []

        SetRecipient text ->
            let
                m = {model | recipients = text, tos = splitRecipients text}
            in
                {m | errorMessage = validate m, successMessage = []} ! []

        MailSendResult (Ok result) ->
            let
                errors = if List.isEmpty result.success then
                             result.message :: result.failed
                         else
                             result.failed
                success = if List.isEmpty result.success then
                              []
                          else
                              result.message :: result.success
            in
                {model | sending = False, errorMessage = errors, successMessage = success} ! []

        MailSendResult (Err error) ->
            {model | sending = False, errorMessage = ["Error sending mails: " ++ (Data.errorMessage error)]} ! [PL.timeoutCmd error]

        SendMail ->
            let
                errors = validate model
            in
                if List.isEmpty errors then
                    {model | sending = True} ! [httpSendMail model]
                else
                    {model | errorMessage = errors} ! []

view: Model -> Html Msg
view model =
    div []
        [
         div [classList [("ui inverted dimmer", True)
                        ,("active", model.sending)
                        ]]
             [
              div [class "ui text loader"][text "Sending ..."]
             ]
        ,form [classList [("ui form", True)
                         ,("error", Data.nonEmpty model.errorMessage)
                         ,("success", Data.nonEmpty model.successMessage)
                         ]]
            [
             div [class "ui success message"]
                 [Data.messagesToHtml model.successMessage]
            ,div [class "ui error message"]
                [Data.messagesToHtml model.errorMessage]
            ,if Data.nonEmpty model.successMessage then
                 div[][]
             else
                 div[]
                     [
                      div [class "ten wide field"]
                          [
                           label [][text "Recipients (separated by comma)"]
                          ,input [name "recipients", type_ "text", value model.recipients, onInput SetRecipient][]
                          ]
                     ,div [class "ten wide field"]
                         [
                          label [][text "Subject"]
                         ,input [name "subject", type_ "text", value model.subject, onInput SetSubject][]
                         ]
                     ,div [class "ten wide field"]
                         [
                          label [][text "Text"]
                         ,textarea [name "text", rows 8, value model.text, onInput SetText][]
                         ]
                     ,a [class "ui primary button", onClick SendMail][text "Send"]
                     ]
            ]
        ]

splitRecipients: String -> List String
splitRecipients line =
    String.split "," line
        |> List.map String.trim


validate: Model -> List String
validate model =
    List.filter (String.isEmpty >> not)
        [if List.isEmpty model.tos then "No recipients set" else ""
        ,if String.isEmpty model.subject then "No subject given" else ""
        ,if String.isEmpty model.text then "No mail text" else ""]


httpSendMail: Model -> Cmd Msg
httpSendMail model =
    Http.post model.urls.mailSend (Http.jsonBody (encodeMail model)) decodeResult
        |> Http.send MailSendResult
