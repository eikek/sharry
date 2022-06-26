module Page.Login.Update exposing (update)

import Api
import Api.Model.AuthResult exposing (AuthResult)
import Api.Model.UserPass exposing (UserPass)
import Browser.Navigation as Nav
import Comp.LanguageChoose
import Data.Flags exposing (Flags)
import Page exposing (Page(..))
import Page.Login.Data exposing (..)
import Ports
import Util.Http
import Util.List


update : ( Maybe Page, Bool ) -> Flags -> Nav.Key -> Msg -> Model -> ( Model, Cmd Msg, Maybe AuthResult )
update ( referrer, oauth ) flags key msg model =
    case msg of
        -- after logging in via some provider, a cookie has been sent
        -- with a redirection to the login page. So then there must be
        -- another call to get the account data.
        Init ->
            if oauth && Util.List.nonEmpty flags.config.oauthConfig then
                ( model, Api.loginSession flags AuthResp, Nothing )

            else if not oauth && Data.Flags.isOAuthAutoRedirect flags && flags.account == Nothing then
                case flags.config.oauthConfig of
                    first :: [] ->
                        ( model, Nav.load (Api.oauthUrl flags first), Nothing )

                    _ ->
                        ( model, Cmd.none, Nothing )

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
                loginSuccess referrer flags lr model

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

        LangChooseMsg lmsg ->
            let
                ( lm, ll ) =
                    Comp.LanguageChoose.update lmsg model.langChoose

                cmd =
                    case ll of
                        Just lang ->
                            Ports.setLang lang

                        Nothing ->
                            Cmd.none
            in
            ( { model | langChoose = lm }, cmd, Nothing )


loginSuccess : Maybe Page -> Flags -> AuthResult -> Model -> ( Model, Cmd Msg, Maybe AuthResult )
loginSuccess referrer flags res model =
    let
        ar =
            Just res

        defaultPage =
            Data.Flags.initialPage flags

        gotoRef =
            Maybe.withDefault defaultPage referrer |> Page.goto
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
