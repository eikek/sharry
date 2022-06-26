module Page.OpenDetail.Update exposing (update)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Comp.PasswordInput
import Comp.ShareFileList
import Data.Flags exposing (Flags)
import Data.InitialView exposing (InitialView)
import Http
import Page.OpenDetail.Data exposing (Model, Msg(..), emptyPassModel)
import Ports
import Util.Http


update : Flags -> InitialView -> Msg -> Model -> ( Model, Cmd Msg )
update flags initialView msg model =
    case msg of
        Init id ->
            let
                share =
                    model.share

                withId =
                    { share | id = id }
            in
            ( { model | share = withId }
            , Api.getOpenShare flags id model.password.field DetailResp
            )

        DetailResp (Ok details) ->
            let
                setView m =
                    case initialView of
                        Data.InitialView.Listing ->
                            { m | fileView = Comp.ShareFileList.ViewList }

                        Data.InitialView.Cards ->
                            { m | fileView = Comp.ShareFileList.ViewCard }

                        Data.InitialView.Zoom ->
                            { m
                                | fileView = Comp.ShareFileList.ViewList
                                , zoom = List.sortBy .filename details.files |> List.head
                            }
            in
            ( setView
                { model
                    | share = details
                    , message = Nothing
                    , password = emptyPassModel
                    , fileListModel = Comp.ShareFileList.reset model.fileListModel
                }
            , Cmd.none
            )

        DetailResp (Err err) ->
            let
                pwm =
                    model.password

                m =
                    Util.Http.errorToString err
            in
            case err of
                Http.BadStatus 401 ->
                    ( { model
                        | password = { pwm | enabled = True, badPassword = False }
                      }
                    , Cmd.none
                    )

                Http.BadStatus 403 ->
                    ( { model
                        | password = { pwm | enabled = True, badPassword = True }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( { model | message = Just (BasicResult False m) }
                    , Cmd.none
                    )

        FileListMsg lmsg ->
            let
                ( m, action ) =
                    Comp.ShareFileList.update lmsg model.fileListModel
            in
            case action of
                Comp.ShareFileList.FileClick sf ->
                    ( { model | fileListModel = m, zoom = Just sf }
                    , Ports.scrollTop ()
                    )

                Comp.ShareFileList.FileDelete sf ->
                    ( model
                    , Cmd.none
                    )

                Comp.ShareFileList.FileNone ->
                    ( { model | fileListModel = m }, Cmd.none )

        SetFileView mode ->
            ( { model
                | fileView = mode
                , fileListModel = Comp.ShareFileList.reset model.fileListModel
              }
            , Cmd.none
            )

        QuitZoom ->
            case model.zoom of
                Just file ->
                    ( { model | zoom = Nothing }, Ports.scrollToElem file.id )

                Nothing ->
                    ( { model | zoom = Nothing }, Cmd.none )

        SetZoom sf ->
            ( { model | zoom = Just sf }, Cmd.none )

        PasswordMsg lmsg ->
            let
                current =
                    model.password

                ( pm, pw ) =
                    Comp.PasswordInput.update lmsg current.model

                next =
                    { current | model = pm, field = pw }
            in
            ( { model | password = next }, Cmd.none )

        SubmitPassword ->
            update flags initialView (Init model.share.id) model
