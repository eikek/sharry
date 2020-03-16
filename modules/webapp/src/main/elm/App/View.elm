module App.View exposing (view)

import Api.Model.AuthResult exposing (AuthResult)
import App.Data exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Markdown
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
    case model.page of
        LoginPage _ ->
            loginLayout model

        RegisterPage ->
            registerLayout model

        _ ->
            defaultLayout model


loginLayout : Model -> Html Msg
loginLayout model =
    div [ class "login-layout" ]
        [ viewLogin model
        , footer model
        ]


registerLayout : Model -> Html Msg
registerLayout model =
    div [ class "register-layout" ]
        [ viewRegister model
        , footer model
        ]


defaultLayout : Model -> Html Msg
defaultLayout model =
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
                , loginInfo model
                ]
            ]
        , div [ class "main-content" ]
            [ case model.page of
                HomePage ->
                    viewHome model

                LoginPage _ ->
                    viewLogin model

                RegisterPage ->
                    viewRegister model

                NewInvitePage ->
                    viewNewInvite model

                InfoPage n ->
                    viewInfo n model

                AccountPage id ->
                    viewAccount id model

                AliasPage id ->
                    viewAlias id model

                UploadPage ->
                    viewUpload model

                SharePage ->
                    viewShare model

                OpenSharePage id ->
                    viewOpenShare id model

                SettingsPage ->
                    viewSettings model

                DetailPage id ->
                    viewDetail id model

                OpenDetailPage id ->
                    viewOpenDetail id model
            ]
        , footer model
        ]


viewOpenDetail : String -> Model -> Html Msg
viewOpenDetail id model =
    Html.map OpenDetailMsg (Page.OpenDetail.View.view model.flags model.openDetailModel)


viewDetail : String -> Model -> Html Msg
viewDetail id model =
    Html.map DetailMsg (Page.Detail.View.view model.flags model.detailModel)


viewSettings : Model -> Html Msg
viewSettings model =
    Html.map SettingsMsg (Page.Settings.View.view model.settingsModel)


viewAlias : Maybe String -> Model -> Html Msg
viewAlias id model =
    Html.map AliasMsg (Page.Alias.View.view model.flags id model.aliasModel)


viewUpload : Model -> Html Msg
viewUpload model =
    Html.map UploadMsg (Page.Upload.View.view model.uploadModel)


viewOpenShare : String -> Model -> Html Msg
viewOpenShare id model =
    Html.map OpenShareMsg (Page.OpenShare.View.view model.flags id model.openShareModel)


viewShare : Model -> Html Msg
viewShare model =
    Html.map ShareMsg (Page.Share.View.view model.flags model.shareModel)


viewAccount : Maybe String -> Model -> Html Msg
viewAccount id model =
    Html.map AccountMsg (Page.Account.View.view id model.accountModel)


viewInfo : Int -> Model -> Html Msg
viewInfo msgnum model =
    Html.map InfoMsg (Page.Info.View.view msgnum model.infoModel)


viewNewInvite : Model -> Html Msg
viewNewInvite model =
    Html.map NewInviteMsg (Page.NewInvite.View.view model.flags model.newInviteModel)


viewRegister : Model -> Html Msg
viewRegister model =
    Html.map RegisterMsg (Page.Register.View.view model.flags model.registerModel)


viewLogin : Model -> Html Msg
viewLogin model =
    Html.map LoginMsg (Page.Login.View.view model.flags model.loginModel)


viewHome : Model -> Html Msg
viewHome model =
    Html.map HomeMsg (Page.Home.View.view model.homeModel)


loginInfo : Model -> Html Msg
loginInfo model =
    div [ class "right menu" ]
        (case model.flags.account of
            Just acc ->
                [ userMenu model acc
                ]

            Nothing ->
                [ a
                    [ class "item"
                    , Page.href (Page.loginPage model.page)
                    ]
                    [ text "Login"
                    ]
                , a
                    [ class "item"
                    , Page.href RegisterPage
                    ]
                    [ text "Register"
                    ]
                ]
        )


userMenu : Model -> AuthResult -> Html Msg
userMenu model acc =
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
                , text "Home"
                ]
            , div [ class "divider" ] []
            , menuEntry model
                UploadPage
                [ i [ class "ui upload icon" ] []
                , text "Shares"
                ]
            , menuEntry model
                (AliasPage Nothing)
                [ i [ class "ui dot circle outline icon" ] []
                , text "Aliases"
                ]
            , if acc.admin then
                menuEntry model
                    (AccountPage Nothing)
                    [ i [ class "ui users icon" ] []
                    , text "Accounts"
                    ]

              else
                span [] []
            , menuEntry model
                SettingsPage
                [ i [ class "ui cog icon" ] []
                , text "Settings"
                ]
            , if acc.admin && model.flags.config.signupMode == "invite" then
                menuEntry model
                    NewInvitePage
                    [ i [ class "ui key icon" ] []
                    , text "New Invites"
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
                , text "Logout ("
                , text acc.user
                , text ")"
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
