module Main exposing (..)

import Api
import App.Data exposing (..)
import App.Update exposing (..)
import App.View exposing (..)
import Browser exposing (Document)
import Browser.Navigation exposing (Key)
import Data.Flags exposing (Flags)
import Data.UploadState exposing (UploadState)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Page exposing (Page(..))
import Ports
import Url exposing (Url)



-- MAIN


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = viewDoc
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = NavRequest
        , onUrlChange = NavChange
        }



-- MODEL


init : Flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    let
        im =
            App.Data.init key url flags

        page =
            checkPage flags im.page

        ( m, cmd ) =
            if im.page == page then
                App.Update.initPage im page

            else
                ( im, Page.goto page )

        sessionCheck =
            case m.flags.account of
                Just _ ->
                    Api.loginSession flags SessionCheckResp

                Nothing ->
                    Cmd.none
    in
    ( m, Cmd.batch [ cmd, Api.versionInfo flags VersionResp, sessionCheck ] )


viewDoc : Model -> Document Msg
viewDoc model =
    { title = model.flags.config.appName
    , body = [ view model ]
    }



-- SUBSCRIPTIONS


uploadStateSub : Sub Msg
uploadStateSub =
    Ports.uploadState (Data.UploadState.decode >> UploadStateMsg)


uploadStopped : Sub Msg
uploadStopped =
    Ports.uploadStopped UploadStoppedMsg


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        uploadSubs =
            Sub.batch
                [ uploadStateSub
                , uploadStopped
                ]
    in
    case model.page of
        SharePage ->
            uploadSubs

        OpenSharePage _ ->
            uploadSubs

        DetailPage _ ->
            uploadSubs

        _ ->
            Sub.none
