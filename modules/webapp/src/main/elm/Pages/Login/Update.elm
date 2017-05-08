module Pages.Login.Update exposing(..)

import String
import Http
import Json.Decode as Decode exposing(field)
import Data exposing (Account)
import Pages.Login.Model exposing(Model, emptyModel)
import Pages.Login.Commands as Commands
import Pages.Login.Data as Data exposing (..)


update: Msg -> Model -> (Model, Cmd Msg, Maybe Account)
update msg model =
    case msg of
        Login name ->
            ({ model | login = name }, Cmd.none, Nothing)

        Password pw ->
            ({ model | password = pw }, Cmd.none, Nothing)

        TryLogin ->
            if String.isEmpty model.login then
                ({model|error = "login is empty"}, Cmd.none, Nothing)
            else
                let c = Commands.authenticate model
                in
                    ({ model | password = "" }, c, Nothing)

        AuthResult (Ok acc) ->
            (emptyModel, Cmd.none, Just acc)

        AuthResult (Err error) ->
            ({model | error = Data.errorMessage error}, Cmd.none, Nothing)
