module App.View exposing (view)

import Api.Model.AuthResult exposing (AuthResult)
import App.Data exposing (..)
import Comp.LanguageChoose
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Markdown
import Messages exposing (Messages)
import Messages.App
import Page exposing (Page(..))
import Page.Account.View
import Page.Alias.View
import Page.Detail.View
import Page.Home.View
import Page.Info.View
import Page.Login.View
import Page.NewInvite.View
import Page.OpenDetail.View
import Page.OpenShare.View
import Page.Register.View
import Page.Settings.View
import Page.Share.View
import Page.Upload.View


view : Model -> Html Msg
view model =
    let
        texts =
            Messages.fromFlags model.flags
    in
    case model.page of
        LoginPage _ ->
            loginLayout texts model

        RegisterPage ->
            registerLayout texts model

        _ ->
            defaultLayout texts model


loginLayout : Messages -> Model -> Html Msg
loginLayout texts model =
    div [ class "login-layout" ]
        [ viewLogin texts model
        , footer model
        ]


registerLayout : Messages -> Model -> Html Msg
registerLayout texts model =
    div [ class "register-layout" ]
        [ viewRegister texts model
        , footer model
        ]


defaultLayout : Messages -> Model -> Html Msg
defaultLayout texts model =
    div [ class "default-layout" ]
        [ div [ class "ui fixed top sticky attached large menu black-bg" ]
            [ div [ class "ui fluid container" ]
                [ a
                    [ class "header item narrow-item"
                    , case model.flags.account of
                        Just _ ->
                            Page.href HomePage

                        Nothing ->
                            href "#"
                    ]
                    [ img
                        [ src <| model.flags.config.iconUrl
                        , class "ui image logo-icon"
                        ]
                        []
                    , text model.flags.config.appName
                    ]
                , loginInfo texts model
                ]
            ]
        , div [ class "main-content" ]
            [ case model.page of
                HomePage ->
                    viewHome texts model

                LoginPage _ ->
                    viewLogin texts model

                RegisterPage ->
                    viewRegister texts model

                NewInvitePage ->
                    viewNewInvite texts model

                InfoPage n ->
                    viewInfo n model

                AccountPage id ->
                    viewAccount id texts model

                AliasPage id ->
                    viewAlias id texts model

                UploadPage ->
                    viewUpload texts model

                SharePage ->
                    viewShare texts model

                OpenSharePage id ->
                    viewOpenShare id texts model

                SettingsPage ->
                    viewSettings texts model

                DetailPage id ->
                    viewDetail id texts model

                OpenDetailPage id ->
                    viewOpenDetail id texts model
            ]
        , footer model
        ]


viewOpenDetail : String -> Messages -> Model -> Html Msg
viewOpenDetail id texts model =
    Html.map OpenDetailMsg (Page.OpenDetail.View.view texts.detail model.flags model.openDetailModel)


viewDetail : String -> Messages -> Model -> Html Msg
viewDetail id texts model =
    Html.map DetailMsg (Page.Detail.View.view texts.detail model.flags model.detailModel)


viewSettings : Messages -> Model -> Html Msg
viewSettings texts model =
    Html.map SettingsMsg (Page.Settings.View.view texts.settings model.settingsModel)


viewAlias : Maybe String -> Messages -> Model -> Html Msg
viewAlias id texts model =
    Html.map AliasMsg (Page.Alias.View.view texts.aliasPage model.flags id model.aliasModel)


viewUpload : Messages -> Model -> Html Msg
viewUpload texts model =
    Html.map UploadMsg (Page.Upload.View.view texts.upload model.uploadModel)


viewOpenShare : String -> Messages -> Model -> Html Msg
viewOpenShare id texts model =
    Html.map OpenShareMsg (Page.OpenShare.View.view texts.share model.flags id model.openShareModel)


viewShare : Messages -> Model -> Html Msg
viewShare texts model =
    Html.map ShareMsg (Page.Share.View.view texts.share model.flags model.shareModel)


viewAccount : Maybe String -> Messages -> Model -> Html Msg
viewAccount id texts model =
    Html.map AccountMsg (Page.Account.View.view id texts.account model.accountModel)


viewInfo : Int -> Model -> Html Msg
viewInfo msgnum model =
    Html.map InfoMsg (Page.Info.View.view msgnum model.infoModel)


viewNewInvite : Messages -> Model -> Html Msg
viewNewInvite texts model =
    Html.map NewInviteMsg (Page.NewInvite.View.view texts.newInvite model.flags model.newInviteModel)


viewRegister : Messages -> Model -> Html Msg
viewRegister texts model =
    Html.map RegisterMsg (Page.Register.View.view texts.register model.flags model.registerModel)


viewLogin : Messages -> Model -> Html Msg
viewLogin texts model =
    Html.map LoginMsg (Page.Login.View.view texts.login model.flags model.loginModel)


viewHome : Messages -> Model -> Html Msg
viewHome texts model =
    Html.map HomeMsg (Page.Home.View.view texts.home model.homeModel)


loginInfo : Messages -> Model -> Html Msg
loginInfo texts model =
    div [ class "right menu" ]
        (case model.flags.account of
            Just acc ->
                [ languageMenu texts model
                , userMenu texts model acc
                ]

            Nothing ->
                [ a
                    [ class "item"
                    , Page.href (Page.loginPage model.page)
                    ]
                    [ text texts.app.login
                    ]
                , a
                    [ class "item"
                    , Page.href RegisterPage
                    ]
                    [ text texts.app.register
                    ]
                , div [ class "divider" ] []
                , languageMenu texts model
                ]
        )


languageMenu : Messages -> Model -> Html Msg
languageMenu texts model =
    Html.map LangChooseMsg
        (Comp.LanguageChoose.viewItem
            texts.login.dropdown
            texts.lang
            model.langChoose
        )


userMenu : Messages -> Model -> AuthResult -> Html Msg
userMenu texts model acc =
    div
        [ class "ui dropdown icon link item"
        , onClick ToggleNavMenu
        ]
        [ i [ class "ui bars icon" ] []
        , div
            [ classList
                [ ( "left menu", True )
                , ( "transition visible", model.navMenuOpen )
                ]
            ]
            [ menuEntry model
                HomePage
                [ img
                    [ class "image icon logo-icon"
                    , src model.flags.config.iconUrl
                    ]
                    []
                , text texts.app.home
                ]
            , div [ class "divider" ] []
            , menuEntry model
                UploadPage
                [ i [ class "ui upload icon" ] []
                , text texts.app.shares
                ]
            , menuEntry model
                (AliasPage Nothing)
                [ i [ class "ui dot circle outline icon" ] []
                , text texts.app.aliases
                ]
            , if acc.admin then
                menuEntry model
                    (AccountPage Nothing)
                    [ i [ class "ui users icon" ] []
                    , text texts.app.accounts
                    ]

              else
                span [] []
            , menuEntry model
                SettingsPage
                [ i [ class "ui cog icon" ] []
                , text texts.app.settings
                ]
            , if acc.admin && model.flags.config.signupMode == "invite" then
                menuEntry model
                    NewInvitePage
                    [ i [ class "ui key icon" ] []
                    , text texts.app.newInvites
                    ]

              else
                span [] []
            , div [ class "divider" ] []
            , a
                [ class "icon item"
                , href ""
                , onClick Logout
                ]
                [ i [ class "sign-out icon" ] []
                , text (texts.app.logout acc.user)
                ]
            ]
        ]


menuEntry : Model -> Page -> List (Html Msg) -> Html Msg
menuEntry model page children =
    a
        [ classList
            [ ( "icon item", True )
            , ( "active", model.page == page )
            ]
        , Page.href page
        ]
        children


footer : Model -> Html Msg
footer model =
    let
        defaultFooter =
            div [ class "ui footer" ]
                [ a [ href "https://eikek.github.io/sharry" ]
                    [ i [ class "ui github icon" ] []
                    , text "Sharry "
                    ]
                , span []
                    [ text model.version.version
                    , text " (#"
                    , String.left 8 model.version.gitCommit |> text
                    , text ")"
                    ]
                ]

        customFooter =
            div [ class "ui footer" ]
                [ Markdown.toHtml [] model.flags.config.footerText
                ]
    in
    if model.flags.config.footerVisible then
        case model.flags.config.footerText of
            "" ->
                defaultFooter

            _ ->
                customFooter

    else
        span [ class "invisible hidden" ] []
