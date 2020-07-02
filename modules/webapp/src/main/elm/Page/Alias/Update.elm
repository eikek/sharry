module Page.Alias.Update exposing (update)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Browser.Navigation as Nav
import Comp.AliasForm exposing (FormAction(..))
import Comp.AliasTable
import Comp.MailSend
import Data.Flags exposing (Flags)
import Page exposing (Page(..))
import Page.Alias.Data
    exposing
        ( Model
        , Msg(..)
        , clipboardData
        )
import Ports
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

                clipboardInit =
                    Ports.initClipboard clipboardData
            in
            if id == "new" then
                ( { model
                    | selected = Nothing
                    , formModel = Comp.AliasForm.initNew flags
                  }
                , clipboardInit
                )

            else if current then
                ( model, clipboardInit )

            else
                ( model
                , Cmd.batch
                    [ Api.getAlias flags id LoadResp
                    , clipboardInit
                    ]
                )

        Init Nothing ->
            ( { model
                | selected = Nothing
                , formModel = Comp.AliasForm.initNew flags
              }
            , Api.listAlias flags model.query SearchResp
            )

        SearchResp (Ok list) ->
            ( { model | searchResult = list.items }, Cmd.none )

        SearchResp (Err err) ->
            ( { model | saveResult = Just <| BasicResult False (Util.Http.errorToString err) }
            , Cmd.none
            )

        LoadResp (Ok alias_) ->
            ( { model
                | selected = Just alias_
                , formModel = Comp.AliasForm.initModify flags alias_
              }
            , Cmd.none
            )

        LoadResp (Err err) ->
            ( model, Cmd.none )

        SetQuery str ->
            ( { model | query = str }
            , Api.listAlias flags str SearchResp
            )

        AliasTableMsg lmsg ->
            let
                ( m, sel ) =
                    Comp.AliasTable.update lmsg model.tableModel

                cmd =
                    Page.set key (AliasPage (Maybe.map .id sel))
            in
            ( { model
                | tableModel = m
                , selected = sel
                , formModel = Comp.AliasForm.init flags sel
              }
            , cmd
            )

        AliasFormMsg lmsg ->
            let
                ( m, action ) =
                    Comp.AliasForm.update lmsg model.formModel

                cmd =
                    case action of
                        FormCreated ac ->
                            Api.createAlias flags ac SaveResp

                        FormModified id am ->
                            Api.modifyAlias flags id am SaveResp

                        FormCancelled ->
                            Page.set key (AliasPage Nothing)

                        FormDelete id ->
                            Api.deleteAlias flags id DeleteResp

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
            ( { model | saveResult = Just <| BasicResult r.success r.message }
            , if Maybe.map .id model.selected /= Just r.id && r.success then
                Page.goto (AliasPage (Just r.id))

              else
                Cmd.none
            )

        SaveResp (Err err) ->
            let
                errmsg =
                    Util.Http.errorToString err
            in
            ( { model | saveResult = Just <| BasicResult False errmsg }
            , Cmd.none
            )

        DeleteResp (Ok r) ->
            ( { model | saveResult = Just r }
            , if r.success then
                Page.goto (AliasPage Nothing)

              else
                Cmd.none
            )

        DeleteResp (Err err) ->
            let
                errmsg =
                    Util.Http.errorToString err
            in
            ( { model | saveResult = Just <| BasicResult False errmsg }
            , Cmd.none
            )

        MailFormMsg lmsg ->
            case model.mailForm of
                Nothing ->
                    ( model, Cmd.none )

                Just msm ->
                    let
                        ( mm, act ) =
                            Comp.MailSend.update flags lmsg msm
                    in
                    case act of
                        Comp.MailSend.Run c ->
                            ( { model | mailForm = Just mm }, Cmd.map MailFormMsg c )

                        Comp.MailSend.Cancelled ->
                            ( { model | mailForm = Nothing }
                            , Cmd.none
                            )

                        Comp.MailSend.Sent ->
                            ( { model | mailForm = Nothing }
                            , Cmd.none
                            )

        InitMail ->
            let
                aliasId =
                    Maybe.map .id model.selected
                        |> Maybe.withDefault ""

                getTpl =
                    Api.getAliasTemplate flags aliasId

                ( mm, mc ) =
                    Comp.MailSend.init getTpl
            in
            ( { model | mailForm = Just mm }
            , Cmd.map MailFormMsg mc
            )
