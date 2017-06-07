module Widgets.AccountForm exposing (..)

import Http
import Html exposing (Html, form, div, h2, button, label, input, text, i, ul, li)
import Html.Attributes exposing (class, classList, type_, value, name, placeholder, checked)
import Html.Events exposing (..)
import Data exposing (Account, accountEncoder, accountDecoder, httpPut, RemoteUrls)
import PageLocation as PL

{- the model -}
type Update
    = Create
    | Modify

type alias Model =
    { account: Account
    , update: Update
    , errors: List String
    , success: Maybe String
    , showPass: Bool
    , url: String
    }

createAccount: RemoteUrls -> String -> Model
createAccount urls login =
    Model (Data.fromLogin login)  Create [] Nothing False urls.accounts

modifyAccount: RemoteUrls -> Account -> Model
modifyAccount urls acc =
    Model {acc|password = Nothing} Modify [] Nothing False urls.accounts

makeModify: Model -> Model
makeModify model =
    let
        acc = model.account
    in
        { model
            | update = Modify
            , errors = []
            , account = {acc | password = Nothing}}

hasError: Model -> Bool
hasError model =
    if List.isEmpty model.errors then False else True

hasSuccess: Model -> Bool
hasSuccess model =
    Data.isPresent model.success

updateAccount: (Account -> Account) -> Model -> Model
updateAccount update model =
    {model | account = update model.account, errors = [], success = Nothing}

type Msg
    = AccountSetPassword String
    | AccountSetEmail String
    | AccountSetEnabled Bool
    | AccountSetAdmin Bool
    | AccountSetExtern Bool
    | SubmitAccount
    | ToggleShowPassword
    | CreateAccountResult (Result Http.Error Account)


{- commands -}

httpCreateAccount: Model -> Cmd Msg
httpCreateAccount model =
    httpPut model.url (Http.jsonBody (accountEncoder model.account)) accountDecoder
        |> Http.send CreateAccountResult

httpModifyAccount: Model -> Cmd Msg
httpModifyAccount model =
    Http.post model.url (Http.jsonBody (accountEncoder model.account)) accountDecoder
        |> Http.send CreateAccountResult


{- update -}

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        AccountSetPassword pass ->
            updateAccount (\acc -> {acc | password = Just pass}) model ! []

        AccountSetEmail email ->
            updateAccount (\acc -> {acc | email = Just email}) model ! []

        AccountSetEnabled flag ->
            updateAccount (\acc -> {acc | enabled = flag}) model ! []

        AccountSetAdmin flag ->
            updateAccount (\acc -> {acc | admin = flag}) model ! []

        AccountSetExtern flag ->
            updateAccount (\acc -> {acc | extern = flag}) model ! []

        CreateAccountResult (Ok acc) ->
            let
                verb = if model.update == Modify then "updated" else "created"
                newmodel = {model | account = acc, success = Just ("The account has been "++ verb ++".")}
            in
                (makeModify newmodel, Cmd.none)

        CreateAccountResult (Err error) ->
            let
                msg = Data.errorMessage error
            in
                {model | errors = msg :: model.errors, success = Nothing} ! [PL.timeoutCmd error]

        ToggleShowPassword ->
            ({model | showPass = (not model.showPass)}, Cmd.none)

        SubmitAccount ->
            case model.update of
                Create ->
                    ({model| errors = [], success = Nothing}, httpCreateAccount model)
                Modify ->
                    ({model | errors = [], success = Nothing}, httpModifyAccount model)


{- view -}

view: Model -> Html Msg
view model =
    let
        acc = model.account
    in
        form [classList [("ui form", True)
                        ,("error", hasError model)
                        ,("success", hasSuccess model)]
             , onSubmit SubmitAccount
             ]
            [
             h2 [class "ui horizontal divider header"]
                 [
                  text acc.login
                 ]
            , div [classList
                       [ ("ui error message", True)
                       , ("visible", (Data.nonEmpty model.errors))
                       ]
                  ]
                 [Data.messagesToHtml model.errors]
            ,div [class "ui success message"]
                [model.success |> Maybe.withDefault "" |> text
                ]
            ,div [class "fields"]
                [
                 div [class "fourteen wide field"]
                     [
                      label [] [text "Password"]
                     ,input [type_ (if model.showPass then "text" else "password")
                            , onInput AccountSetPassword
                            , value (Maybe.withDefault "" acc.password)
                            , name "password"
                            , placeholder "password"][]
                     ]
                ,div [class "two wide field"]
                    [
                     label [] [text "Show"]
                    ,button [type_ "button"
                            , class "ui button"
                            , onClick ToggleShowPassword
                            ]
                         [text (if model.showPass then "Hide" else "Show")]
                    ]
                ]
            ,div [class "field"]
                [
                 label [] [text "Email"]
                ,input [type_ "text"
                       , onInput AccountSetEmail
                       , value (Maybe.withDefault "" acc.email)
                       , name "email"
                       , placeholder "optional email address"][]
                ]
            ,div [class "field"]
                [
                 div [class "ui checkbox"]
                     [
                      input [type_ "checkbox"
                            , checked acc.enabled
                            , onCheck AccountSetEnabled][]
                     ,label [] [text "Enabled"]
                     ]
                ]
            ,div [class "field"]
                [
                 div [class "ui checkbox"]
                     [
                      input [type_ "checkbox"
                            , checked acc.admin
                            , onCheck AccountSetAdmin][]
                     ,label [] [text "Admin"]
                     ]
                ]
            ,div [class "field"]
                [
                 div [class "ui checkbox"]
                     [
                      input [type_ "checkbox"
                            , checked acc.extern
                            , onCheck AccountSetExtern][]
                     ,label [] [text "Extern"]
                     ]
                ]
            ,button [class "ui button", type_ "submit"] [text "Submit"]
        ]
