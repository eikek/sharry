module Widgets.LoginSearch exposing (..)

import Http
import Html exposing (Html, div, text, a, i, input)
import Html.Attributes exposing (class, classList, value, placeholder, type_)
import Html.Events exposing (onInput, onClick)
import Json.Decode as Decode exposing(field)
import Json.Encode as Encode
import Data exposing (Account, RemoteUrls, accountDecoder)

type State
    = Init
    | Searching
    | SearchDone
    | Selected

type alias Model =
    { login: String
    , results: List String
    , active: String
    , state: State
    , errorMsg: String
    , url: String
    }

type Msg
    = SetSearch String
    | SelectLogin String
    | SearchResult (Result Http.Error (List String))
    | GetAccountResult (Result Http.Error Account)
{-    | SetActiveResult (Maybe String) -}

initModel: RemoteUrls -> Model
initModel urls =
    Model "" [] "" Init "" urls.accounts

errorModel: Model -> String -> Model
errorModel model msg =
    {model | errorMsg = msg, results = [], active = "", state = Init}


{-- Commands --}


searchLogins: Model -> Cmd Msg
searchLogins model =
    let
        url = model.url ++ "?q=" ++ (Http.encodeUri model.login)
    in
    Http.get url decodeLoginList
        |> Http.send SearchResult

decodeLoginList: Decode.Decoder (List String)
decodeLoginList =
    Decode.list Decode.string


fetchAccount: Model -> Cmd Msg
fetchAccount model =
    Http.get (model.url ++ "/" ++ (Http.encodeUri model.login)) accountDecoder
        |> Http.send GetAccountResult


{-- update --}

update: Msg -> Model -> (Model, Cmd Msg, Maybe Account)
update msg model =
    case msg of
        SetSearch login ->
            let
                new = {model | login = login, state = Searching}
            in
            (new, searchLogins new, Nothing)

        SearchResult (Ok logins) ->
            ({model
                 | results = logins
                 , state = SearchDone
             }
            , Cmd.none, Nothing)

        SearchResult (Err error) ->
            ({model
                 | state = Init
                 , errorMsg = (Data.errorMessage error)
             }
            , Cmd.none, Nothing)

        SelectLogin login ->
            let
                new = { model
                          | login = login
                          , results = []
                          , errorMsg = ""
                          , state = Selected
                      }
            in
            (new, fetchAccount new, Nothing)

        GetAccountResult (Ok acc) ->
            ({model | errorMsg = ""}, Cmd.none, Just acc)

        GetAccountResult (Err error) ->
            (errorModel model (Data.errorMessage error) , Cmd.none, Nothing)

{-- view --}


view: Model -> Html Msg
view model =
    div [classList [("ui search focus", True)
                   ,("loading", model.state == Searching)]
        ]
        [
         div [class "ui icon input fluid"]
             [
              input [class "prompt", type_ "text", placeholder "Logins…", value model.login, onInput SetSearch] []
             , i [class "search icon"] []
             ]
        ,div [classList [("results", True)
                        ,("transition visible", Data.nonEmpty model.results)
                        ,("transition hidden", List.isEmpty model.results)
                        ]
             ]
             (List.map (menuItem model) model.results)
        ]

menuItem: Model -> String -> Html Msg
menuItem model login =
    a [classList [("result", True), ("active", login == model.active)], onClick (SelectLogin login)]
        [
         div [class "content"]
             [
              div [class "title"]
                  [text login]
             ]
        ]
