module Widgets.UpdatePasswordForm exposing (..)

import Html exposing (Html, div, i, h4, text, input, button, form)
import Html.Attributes exposing (class, classList, type_, placeholder, value)
import Html.Events exposing (onInput, onSubmit)
import Http

import Data exposing (Account, RemoteUrls)
import PageLocation as PL

type alias Model =
    {account: Account
    ,urls: RemoteUrls
    ,password: Maybe String
    ,passwordConfirm: Maybe String
    ,infoMessage: Maybe String
    ,errorMessage: Maybe String
    }

makeModel: Account -> RemoteUrls -> Model
makeModel acc urls =
    Model acc urls Nothing Nothing Nothing Nothing

hasInfo: Model -> Bool
hasInfo model =
    Data.isPresent model.infoMessage

hasError: Model -> Bool
hasError model =
    Data.isPresent model.errorMessage

type Msg
    = SetPassword String
    | SetPasswordConfirm String
    | UpdatePassword
    | UpdatePasswordResult (Result Http.Error Account)

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        SetPassword pw ->
            {model | password = Data.nonEmptyStr pw, infoMessage = Nothing, errorMessage = Nothing} ! []

        SetPasswordConfirm pw ->
            {model | passwordConfirm = Data.nonEmptyStr pw, infoMessage = Nothing, errorMessage = Nothing} ! []

        UpdatePasswordResult (Ok acc) ->
            {model | account = acc, infoMessage = Just "Password was updated."} ! []

        UpdatePasswordResult (Err error) ->
            {model | errorMessage = Data.errorMessage error |> Just} ! [PL.timeoutCmd error]

        UpdatePassword ->
            let
                same = model.password == model.passwordConfirm
                change acc = {acc | password = model.password}
                m = {model | account = change model.account}
            in
                if model.account.extern then
                    {model | errorMessage = Just "Password cannot be changed for external accounts"} ! []
                else if same then
                    m ! [httpUpdatePassword m]
                else
                    {model | errorMessage = Just "Passwords are not equal."} ! []

view: Model -> Html Msg
view model =
    div []
        [
         h4 [class "ui dividing header"][text "Change Password"]
        ,form [classList [("ui form", True)
                         ,("error", hasError model)
                         ,("success", hasInfo model)]
              ,onSubmit UpdatePassword
              ]
            [
             div [classList [("ui inverted dimmer", True)
                            ,("active", model.account.extern)]]
                 [
                  div [class "content"]
                      [
                       div [class "center"]
                           [
                            h4 [class "ui icon header"]
                                [
                                 i [class "announcement icon"][]
                                ,text "Passwords cannot be changed for external accounts."
                                ]
                           ]
                      ]
                 ]
            ,div [class "eight wide field"]
                 [
                  div [class "ui large left icon input"]
                      [
                       i [class "lock icon"] []
                      ,input [onInput SetPassword, type_ "password", placeholder "Password"] []
                      ]
                 ]
            ,div [class "eight wide field"]
                [
                 div [class "ui large left icon input"]
                     [
                      i [class "lock icon"][]
                     ,input [onInput SetPasswordConfirm, type_ "password", placeholder "Confirm"][]
                     ]
                ]
            ,button [class "ui primary submit button", type_ "sumit"]
                [text "Submit"]
            ,div [classList [("hidden", False)
                            ,("ui icon success message", True)]]
                [
                 i [class "smile icon"][]
                ,div [class "content"]
                    [model.infoMessage |> Maybe.withDefault "" |> text]
                ]
            ,div [classList [("hidden", False)
                            ,("ui icon error message", True)]]
                [
                 i [class "frown icon"][]
                ,div [class "content"]
                    [model.errorMessage |> Maybe.withDefault "" |> text]
                ]
            ]
        ]

httpUpdatePassword: Model -> Cmd Msg
httpUpdatePassword model =
    Http.post model.urls.profilePassword (Http.jsonBody (Data.accountEncoder model.account)) Data.accountDecoder
        |> Http.send UpdatePasswordResult
