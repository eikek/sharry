module Page.Settings.Update exposing (update)

import Api
import Api.Model.PasswordChange exposing (PasswordChange)
import Comp.PasswordInput
import Data.Flags exposing (Flags)
import Page.Settings.Data exposing (Banner, Model, Msg(..))
import Util.Http
import Util.Maybe


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        Init ->
            ( { model | banner = Nothing }
            , Cmd.batch
                [ Api.getEmail flags GetEmailResp
                , Api.checkPassword flags CheckPassResp
                ]
            )

        CheckPassResp res ->
            let
                flag =
                    Result.map .success res
                        |> Result.withDefault False
            in
            ( { model | passwordAvailable = Just flag }
            , Cmd.none
            )

        GetEmailResp (Ok r) ->
            ( { model
                | currentEmail = r.email
                , emailField =
                    if model.emailField == Nothing then
                        r.email

                    else
                        model.emailField
              }
            , Cmd.none
            )

        GetEmailResp (Err err) ->
            ( { model
                | banner =
                    Just <|
                        Banner False <|
                            "Error retrieving current email: "
                                ++ Util.Http.errorToString err
              }
            , Cmd.none
            )

        SetEmail str ->
            let
                em =
                    Util.Maybe.fromString str
            in
            ( { model | emailField = em, banner = Nothing }, Cmd.none )

        SubmitEmail ->
            if model.currentEmail == model.emailField then
                ( { model
                    | banner =
                        Just <|
                            Banner False "E-Mail has not changed."
                  }
                , Cmd.none
                )

            else
                ( model, Api.setEmail flags model.emailField SaveResp )

        SaveResp (Ok r) ->
            ( { model | banner = Just <| Banner r.success r.message }, Cmd.none )

        SaveResp (Err err) ->
            ( { model
                | banner =
                    Just <|
                        Banner False <|
                            "Error on submit: "
                                ++ Util.Http.errorToString err
              }
            , Cmd.none
            )

        SetOldPassword lmsg ->
            let
                ( m, pw ) =
                    Comp.PasswordInput.update lmsg model.oldPasswordModel
            in
            ( { model
                | oldPasswordModel = m
                , oldPasswordField = pw
                , banner = Nothing
              }
            , Cmd.none
            )

        SetNewPassword1 lmsg ->
            let
                ( m, pw ) =
                    Comp.PasswordInput.update lmsg model.newPasswordModel1
            in
            ( { model
                | newPasswordModel1 = m
                , newPasswordField1 = pw
                , banner = Nothing
              }
            , Cmd.none
            )

        SetNewPassword2 lmsg ->
            let
                ( m, pw ) =
                    Comp.PasswordInput.update lmsg model.newPasswordModel2
            in
            ( { model
                | newPasswordModel2 = m
                , newPasswordField2 = pw
                , banner = Nothing
              }
            , Cmd.none
            )

        SubmitPassword ->
            let
                bothEqual =
                    model.newPasswordField1
                        == model.newPasswordField2
                        && model.newPasswordField1
                        /= Nothing

                pwc =
                    PasswordChange
                        (Maybe.withDefault "" model.oldPasswordField)
                        (Maybe.withDefault "" model.newPasswordField1)
            in
            if bothEqual then
                ( model, Api.changePassword flags pwc SaveResp )

            else
                ( { model | banner = Just <| Banner False "Passwords don't match." }
                , Cmd.none
                )
