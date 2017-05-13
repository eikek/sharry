module Widgets.UpdateEmailForm exposing (..)

import Html exposing (Html, div, i, h4, text, input, button)
import Html.Attributes exposing (class, classList, type_, placeholder, value)
import Html.Events exposing (onInput, onClick)
import Http

import Data exposing (Account, RemoteUrls)

type alias Model =
    {account: Account
    ,urls: RemoteUrls
    ,email: Maybe String
    ,infoMessage: Maybe String
    ,errorMessage: Maybe String
    }

makeModel: Account -> RemoteUrls -> Model
makeModel acc urls =
    Model acc urls acc.email Nothing Nothing

hasInfo: Model -> Bool
hasInfo model =
    Data.isPresent model.infoMessage

hasError: Model -> Bool
hasError model =
    Data.isPresent model.errorMessage

type Msg
    = SetEmail String
    | UpdateEmail
    | UpdateEmailResult (Result Http.Error Account)

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        SetEmail em ->
            {model | email = Data.nonEmptyStr em, infoMessage = Nothing, errorMessage = Nothing} ! []

        UpdateEmailResult (Ok acc) ->
            {model | account = acc, email = acc.email, infoMessage = Just "Email was updated."} ! []

        UpdateEmailResult (Err error) ->
            {model | errorMessage = Data.errorMessage error |> Just} ! []

        UpdateEmail ->
            let
                change acc = {acc | email = model.email}
                m = {model | account = change model.account}
            in
                m ! [httpUpdateEmail m]


view: Model -> Html Msg
view model =
    let
        address = Maybe.withDefault "" model.email
    in
    div []
        [
         h4 [class "ui dividing header"][text "Change Email"]
        ,div [class "ui large right action left icon input"]
            [
             i [class "at icon"] []
            ,input [onInput SetEmail, type_ "text", placeholder "Email", value address] []
            ,button [class "ui floating primary submit button", onClick UpdateEmail] [ text "Submit" ]
            ]
        ,div [classList [("hidden", not (hasInfo model))
                        ,("ui icon success message", True)]]
            [
             i [class "smile icon"][]
            ,div [class "content"]
                [model.infoMessage |> Maybe.withDefault "" |> text]
            ]
        ,div [classList [("hidden", not (hasError model))
                        ,("ui icon error message", True)]]
            [
             i [class "frown icon"][]
            ,div [class "content"]
                [model.errorMessage |> Maybe.withDefault "" |> text]
            ]
        ,div [classList [("hidden", hasInfo model || hasError model)
                        ,("ui icon info message", True)]]
            [
             i [class "info icon"][]
            ,div [class "content"]
                [text "Submitting an empty email field will delete it from your profile."]
            ]
        ]

httpUpdateEmail: Model -> Cmd Msg
httpUpdateEmail model =
    Http.post model.urls.profileEmail (Http.jsonBody (Data.accountEncoder model.account)) Data.accountDecoder
        |> Http.send UpdateEmailResult
