module Page.Account.Update exposing (update)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Browser.Navigation as Nav
import Comp.AccountForm exposing (FormAction(..))
import Comp.AccountTable
import Data.Flags exposing (Flags)
import Page exposing (Page(..))
import Page.Account.Data exposing (Model, Msg(..))
import Util.Http


update : Nav.Key -> Flags -> Msg -> Model -> ( Model, Cmd Msg )
update key flags msg model =
    case msg of
        Init (Just id) ->
            let
                current =
                    Maybe.map .id model.selected
                        |> Maybe.map ((==) id)
                        |> Maybe.withDefault False
            in
            if id == "new" then
                ( { model
                    | selected = Nothing
                    , formModel = Comp.AccountForm.initNew
                  }
                , Cmd.none
                )

            else if current then
                ( model, Cmd.none )

            else
                ( model, Api.loadAccount flags id LoadResp )

        Init Nothing ->
            ( { model
                | selected = Nothing
                , formModel = Comp.AccountForm.initNew
              }
            , Api.listAccounts flags model.query SearchResp
            )

        SearchResp (Ok list) ->
            ( { model | searchResult = list.items }, Cmd.none )

        SearchResp (Err err) ->
            ( model, Cmd.none )

        LoadResp (Ok acc) ->
            ( { model
                | selected = Just acc
                , formModel = Comp.AccountForm.initModify acc
              }
            , Cmd.none
            )

        LoadResp (Err err) ->
            ( model, Cmd.none )

        SetQuery str ->
            ( { model | query = str }
            , Api.listAccounts flags str SearchResp
            )

        AccountTableMsg lmsg ->
            let
                ( m, sel ) =
                    Comp.AccountTable.update lmsg model.tableModel

                cmd =
                    Page.set key (AccountPage (Maybe.map .id sel))
            in
            ( { model
                | tableModel = m
                , selected = sel
                , formModel = Comp.AccountForm.init sel
              }
            , cmd
            )

        AccountFormMsg lmsg ->
            let
                ( m, action ) =
                    Comp.AccountForm.update lmsg model.formModel

                cmd =
                    case action of
                        FormCreated ac ->
                            Api.createAccount flags ac SaveResp

                        FormModified id am ->
                            Api.modifyAccount flags id am SaveResp

                        FormCancelled ->
                            Page.set key (AccountPage Nothing)

                        FormNone ->
                            Cmd.none
            in
            ( { model
                | formModel = m
                , saveResult = Nothing
              }
            , cmd
            )

        SaveResp (Ok r) ->
            ( { model | saveResult = Just r }, Cmd.none )

        SaveResp (Err err) ->
            let
                errmsg =
                    Util.Http.errorToString err
            in
            ( { model | saveResult = Just <| BasicResult False errmsg }
            , Cmd.none
            )
