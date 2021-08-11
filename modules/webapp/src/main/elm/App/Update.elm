module App.Update exposing (initPage, update)

import Api
import App.Data exposing (..)
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Data.Flags
import Data.UiTheme
import Page exposing (Page(..))
import Page.Account.Data
import Page.Account.Update
import Page.Alias.Data
import Page.Alias.Update
import Page.Detail.Data
import Page.Detail.Update
import Page.Home.Data
import Page.Home.Update
import Page.Info.Data
import Page.Info.Update
import Page.Login.Data
import Page.Login.Update
import Page.NewInvite.Data
import Page.NewInvite.Update
import Page.OpenDetail.Data
import Page.OpenDetail.Update
import Page.OpenShare.Data
import Page.OpenShare.Update
import Page.Register.Data
import Page.Register.Update
import Page.Settings.Data
import Page.Settings.Update
import Page.Share.Data
import Page.Share.Update
import Page.Upload.Data
import Page.Upload.Update
import Ports
import Url
import Util.Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleDarkMode ->
            let
                next =
                    Data.UiTheme.cycle model.uiTheme
            in
            ( { model
                | uiTheme = next
                , navMenuOpen = False
              }
            , Ports.setUiTheme next
            )

        HomeMsg lm ->
            updateHome lm model

        LoginMsg lm ->
            updateLogin lm model

        RegisterMsg lm ->
            updateRegister lm model

        NewInviteMsg lm ->
            updateNewInvite lm model

        InfoMsg lm ->
            updateInfo lm model

        AccountMsg lm ->
            updateAccount lm model

        AliasMsg lm ->
            updateAlias lm model

        UploadMsg lm ->
            updateUpload lm model

        ShareMsg lm ->
            updateShare lm model

        OpenShareMsg lm ->
            updateOpenShare lm model

        SettingsMsg lm ->
            updateSettings lm model

        DetailMsg lm ->
            updateDetail lm model

        OpenDetailMsg lm ->
            updateOpenDetail lm model

        SetPage p ->
            ( { model | page = p }
            , Cmd.none
            )

        ToggleNavMenu ->
            ( { model
                | navMenuOpen = not model.navMenuOpen
                , langMenuOpen =
                    if model.navMenuOpen then
                        model.langMenuOpen

                    else
                        False
              }
            , Cmd.none
            )

        UploadStateMsg (Ok lmsg) ->
            Util.Update.andThen1
                [ updateShare (Page.Share.Data.Uploading lmsg)
                , updateOpenShare (Page.OpenShare.Data.Uploading lmsg)
                , updateDetail (Page.Detail.Data.Uploading lmsg)
                ]
                model

        UploadStoppedMsg err ->
            Util.Update.andThen1
                [ updateShare (Page.Share.Data.UploadStopped err)
                , updateOpenShare (Page.OpenShare.Data.UploadStopped err)
                , updateDetail (Page.Detail.Data.UploadStopped err)
                ]
                model

        UploadStateMsg (Err _) ->
            ( model, Cmd.none )

        VersionResp (Ok info) ->
            ( { model | version = info }, Cmd.none )

        VersionResp (Err _) ->
            ( model, Cmd.none )

        Logout ->
            ( model
            , Cmd.batch
                [ Api.logout model.flags LogoutResp
                , Ports.removeAccount ()
                ]
            )

        LogoutResp _ ->
            ( { model | loginModel = Page.Login.Data.empty }
            , Page.goto (LoginPage ( Nothing, False ))
            )

        SessionCheckResp res ->
            case res of
                Ok lr ->
                    let
                        newFlags =
                            if lr.success then
                                Data.Flags.withAccount model.flags lr

                            else
                                Data.Flags.withoutAccount model.flags

                        command =
                            if lr.success then
                                Api.refreshSession newFlags SessionCheckResp

                            else
                                Cmd.batch [ Ports.removeAccount (), Page.goto (Page.loginPage model.page) ]
                    in
                    ( { model | flags = newFlags }, command )

                Err _ ->
                    ( model, Cmd.batch [ Ports.removeAccount (), Page.goto (Page.loginPage model.page) ] )

        NavRequest req ->
            case req of
                Internal url ->
                    let
                        urlStr =
                            Url.toString url

                        extern =
                            not <|
                                String.startsWith
                                    (model.flags.config.baseUrl ++ "/app")
                                    urlStr

                        isCurrent =
                            Page.fromUrl url
                                |> Maybe.map (\p -> p == model.page)
                                |> Maybe.withDefault True
                    in
                    ( model
                    , if extern then
                        Nav.load urlStr

                      else if isCurrent then
                        Cmd.none

                      else
                        Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        NavChange url ->
            let
                page =
                    Page.fromUrl url |> Maybe.withDefault HomePage

                ( m, c ) =
                    initPage model page
            in
            ( { m | page = page }, c )

        ReceiveLanguage lang ->
            let
                flags =
                    model.flags

                nf =
                    { flags | language = Just lang }
            in
            ( { model | flags = nf }
            , Cmd.none
            )

        ToggleLangMenu ->
            ( { model
                | langMenuOpen = not model.langMenuOpen
                , navMenuOpen =
                    if model.langMenuOpen then
                        model.navMenuOpen

                    else
                        False
              }
            , Cmd.none
            )

        SetLanguage lang ->
            ( { model | langMenuOpen = False }
            , Ports.setLang lang
            )


updateOpenDetail : Page.OpenDetail.Data.Msg -> Model -> ( Model, Cmd Msg )
updateOpenDetail lmsg model =
    let
        ( lm, lc ) =
            Page.OpenDetail.Update.update model.flags lmsg model.openDetailModel
    in
    ( { model | openDetailModel = lm }
    , Cmd.map OpenDetailMsg lc
    )


updateDetail : Page.Detail.Data.Msg -> Model -> ( Model, Cmd Msg )
updateDetail lmsg model =
    let
        ( lm, lc ) =
            Page.Detail.Update.update model.flags lmsg model.detailModel
    in
    ( { model | detailModel = lm }
    , Cmd.map DetailMsg lc
    )


updateSettings : Page.Settings.Data.Msg -> Model -> ( Model, Cmd Msg )
updateSettings lmsg model =
    let
        ( lm, lc ) =
            Page.Settings.Update.update model.flags lmsg model.settingsModel
    in
    ( { model | settingsModel = lm }
    , Cmd.map SettingsMsg lc
    )


updateAlias : Page.Alias.Data.Msg -> Model -> ( Model, Cmd Msg )
updateAlias lmsg model =
    let
        ( lm, lc ) =
            Page.Alias.Update.update model.key model.flags lmsg model.aliasModel
    in
    ( { model | aliasModel = lm }
    , Cmd.map AliasMsg lc
    )


updateUpload : Page.Upload.Data.Msg -> Model -> ( Model, Cmd Msg )
updateUpload lmsg model =
    let
        ( lm, lc ) =
            Page.Upload.Update.update model.key model.flags lmsg model.uploadModel
    in
    ( { model | uploadModel = lm }
    , Cmd.map UploadMsg lc
    )


updateOpenShare : Page.OpenShare.Data.Msg -> Model -> ( Model, Cmd Msg )
updateOpenShare lmsg model =
    let
        aliasId =
            case model.page of
                OpenSharePage id ->
                    id

                _ ->
                    ""

        ( lm, lc ) =
            Page.OpenShare.Update.update aliasId model.flags lmsg model.openShareModel
    in
    ( { model | openShareModel = lm }
    , Cmd.map OpenShareMsg lc
    )


updateShare : Page.Share.Data.Msg -> Model -> ( Model, Cmd Msg )
updateShare lmsg model =
    let
        ( lm, lc ) =
            Page.Share.Update.update model.flags lmsg model.shareModel
    in
    ( { model | shareModel = lm }
    , Cmd.map ShareMsg lc
    )


updateAccount : Page.Account.Data.Msg -> Model -> ( Model, Cmd Msg )
updateAccount lmsg model =
    let
        ( lm, lc ) =
            Page.Account.Update.update model.key model.flags lmsg model.accountModel
    in
    ( { model | accountModel = lm }
    , Cmd.map AccountMsg lc
    )


updateRegister : Page.Register.Data.Msg -> Model -> ( Model, Cmd Msg )
updateRegister lmsg model =
    let
        ( lm, lc ) =
            Page.Register.Update.update model.flags lmsg model.registerModel
    in
    ( { model | registerModel = lm }
    , Cmd.map RegisterMsg lc
    )


updateNewInvite : Page.NewInvite.Data.Msg -> Model -> ( Model, Cmd Msg )
updateNewInvite lmsg model =
    let
        ( lm, lc ) =
            Page.NewInvite.Update.update model.flags lmsg model.newInviteModel
    in
    ( { model | newInviteModel = lm }
    , Cmd.map NewInviteMsg lc
    )


updateLogin : Page.Login.Data.Msg -> Model -> ( Model, Cmd Msg )
updateLogin lmsg model =
    let
        ( lm, lc, ar ) =
            Page.Login.Update.update (Page.loginPageReferrer model.page) model.flags lmsg model.loginModel

        newFlags =
            Maybe.map (Data.Flags.withAccount model.flags) ar
                |> Maybe.withDefault model.flags
    in
    ( { model | loginModel = lm, flags = newFlags }
    , Cmd.map LoginMsg lc
    )


updateHome : Page.Home.Data.Msg -> Model -> ( Model, Cmd Msg )
updateHome lmsg model =
    let
        ( lm, lc ) =
            Page.Home.Update.update model.flags lmsg model.homeModel
    in
    ( { model | homeModel = lm }
    , Cmd.map HomeMsg lc
    )


updateInfo : Page.Info.Data.Msg -> Model -> ( Model, Cmd Msg )
updateInfo lmsg model =
    let
        ( lm, lc ) =
            Page.Info.Update.update model.flags lmsg model.infoModel
    in
    ( { model | infoModel = lm }
    , Cmd.map InfoMsg lc
    )


initPage : Model -> Page -> ( Model, Cmd Msg )
initPage model page =
    case page of
        HomePage ->
            ( model, Cmd.none )

        LoginPage _ ->
            updateLogin Page.Login.Data.Init model

        RegisterPage ->
            ( model, Cmd.none )

        NewInvitePage ->
            ( model, Cmd.none )

        InfoPage _ ->
            ( model, Cmd.none )

        AccountPage aid ->
            updateAccount (Page.Account.Data.Init aid) model

        AliasPage aid ->
            updateAlias (Page.Alias.Data.Init aid) model

        UploadPage ->
            updateUpload Page.Upload.Data.Init model

        SharePage ->
            ( model, Cmd.none )

        OpenSharePage _ ->
            ( model, Cmd.none )

        SettingsPage ->
            updateSettings Page.Settings.Data.Init model

        DetailPage id ->
            updateDetail (Page.Detail.Data.Init id) model

        OpenDetailPage id ->
            updateOpenDetail (Page.OpenDetail.Data.Init id) model
