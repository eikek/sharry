module Page.Login.Update exposing (update)

import Api
import Api.Model.AuthResult exposing (AuthResult)
import Api.Model.UserPass exposing (UserPass)
import Data.Flags exposing (Flags)
import Page exposing (Page(..))
import Page.Login.Data exposing (..)
import Ports
import Util.Http
import Util.List


update : ( Maybe Page, Bool ) -> Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe AuthResult )
update ( referrer, oauth ) flags msg model =
    case msg of
        -- after logging in via some provider, a cookie has been sent
        -- with a redirection to the login page. So then there must be
        -- another call to get the account data.
        Init ->
            if oauth && Util.List.nonEmpty flags.config.oauthConfig then
                ( model, Api.loginSession flags AuthResp, Nothing )

            else
                ( model, Cmd.none, Nothing )

        SetUsername str ->
            ( { model | username = str }, Cmd.none, Nothing )

        SetPassword str ->
            ( { model | password = str }, Cmd.none, Nothing )

        Authenticate ->
            ( model, Api.login flags (UserPass model.username model.password) AuthResp, Nothing )

        AuthResp (Ok lr) ->
            if lr.success then
                loginSuccess referrer lr model

            else
                ( { model | result = Just lr, password = "" }
                , Ports.removeAccount ()
                , Just lr
                )

        AuthResp (Err err) ->
            let
                empty =
                    Api.Model.AuthResult.empty

                lr =
                    { empty | message = Util.Http.errorToString err }
            in
            ( { model | password = "", result = Just lr }, Ports.removeAccount (), Just empty )

        SetLanguage lang ->
            ( model, Ports.setLang lang, Nothing )


loginSuccess : Maybe Page -> AuthResult -> Model -> ( Model, Cmd Msg, Maybe AuthResult )
loginSuccess referrer res model =
    let
        ar =
            Just res

        gotoRef =
            Maybe.withDefault HomePage referrer |> Page.goto
    in
    ( { model | result = ar, password = "" }
    , Cmd.batch [ setAccount res, gotoRef ]
    , ar
    )


setAccount : AuthResult -> Cmd msg
setAccount result =
    if result.success then
        Ports.setAccount result

    else
        Ports.removeAccount ()
