module Pages.AccountEdit.Update exposing (..)

import Data exposing (Account)
import Pages.AccountEdit.Model exposing (..)

import Widgets.AccountForm as AccountForm
import Widgets.LoginSearch as LoginSearch

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    let
        search = model.search
    in
    case msg of
        NewAccount ->
            let
                acc = Data.emptyAccount
            in
            ({model
                 | accountForm = Just (AccountForm.createAccount model.urls model.search.login)
                 , search = LoginSearch.initModel model.urls
                 , errorMsg = ""
             }
            , Cmd.none)

        LoginSearchMsg msg ->
            let
                (val, cmd, acc) = LoginSearch.update msg model.search
            in
                case acc of
                    Just a ->
                        ({model
                             | search = val
                             , accountForm = Just (AccountForm.modifyAccount model.urls a)
                         }
                        , Cmd.map LoginSearchMsg cmd)

                    Nothing ->
                        ({model | search = val}, Cmd.map LoginSearchMsg cmd)

        AccountFormMsg msg ->
            case model.accountForm of
                Just m ->
                    let
                        (val, cmd) = AccountForm.update msg m
                    in
                        ({model | accountForm = Just val}
                        ,Cmd.map AccountFormMsg cmd)

                Nothing ->
                    (model, Cmd.none)
