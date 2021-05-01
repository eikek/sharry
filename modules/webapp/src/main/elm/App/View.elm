module App.View exposing (view)

import Api.Model.AuthResult exposing (AuthResult)
import App.Data exposing (..)
import Comp.LanguageChoose
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Markdown
import Messages exposing (Messages)
import Page exposing (Page(..))
import Page.Account.View
import Page.Alias.View
import Page.Detail.View
import Page.Home.View
import Page.Info.View
import Page.Login.View2
import Page.NewInvite.View
import Page.OpenDetail.View
import Page.OpenShare.View
import Page.Register.View2
import Page.Settings.View
import Page.Share.View
import Page.Upload.View
import Styles as S


view : Model -> Html Msg
view model =
    let
        texts =
            Messages.fromFlags model.flags
    in
    div
        [ id "main"
        , class styleMain
        ]
        [ topMenu texts model
        , mainContent texts model
        , footer model
        ]


topMenu : Messages -> Model -> Html Msg
topMenu texts model =
    case model.flags.account of
        Just acc ->
            topMenuUser acc texts model

        Nothing ->
            topMenuAnon texts model


topMenuAnon : Messages -> Model -> Html Msg
topMenuAnon texts model =
    nav
        [ id "top-nav"
        , class styleTopNav
        ]
        [ headerNavItem model
        , div
            [ class "flex flex-grow justify-end"
            ]
            [ a
                [ href "#"
                , onClick ToggleDarkMode
                , class dropdownLink
                ]
                [ i [ class "fa fa-adjust w-6" ] []
                ]
            ]
        ]


headerNavItem : Model -> Html Msg
headerNavItem model =
    a
        [ class "inline-flex font-bold hover:bg-indigo-200 dark:hover:bg-warmgray-800 items-center px-4"
        , Page.href HomePage
        ]
        [ img
            [ src model.flags.config.iconUrl
            , class "w-9 h-9 mr-2 block"
            ]
            []
        , div [ class "" ]
            [ text model.flags.config.appName
            ]
        ]


topMenuUser : AuthResult -> Messages -> Model -> Html Msg
topMenuUser account texts model =
    div [ class styleTopNav ]
        [ headerNavItem model
        , div [ class "flex flex-grow justify-end" ]
            [ languageMenu texts model
            , userMenu texts model account
            ]
        ]


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
                , ( "transition hidden", not model.navMenuOpen )
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


mainContent : Messages -> Model -> Html Msg
mainContent texts model =
    div
        [ id "content"
        , class styleMain
        ]
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


viewOpenDetail : String -> Messages -> Model -> Html Msg
viewOpenDetail _ texts model =
    Html.map OpenDetailMsg (Page.OpenDetail.View.view texts.detail model.flags model.openDetailModel)


viewDetail : String -> Messages -> Model -> Html Msg
viewDetail _ texts model =
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
    Html.map RegisterMsg (Page.Register.View2.view texts.register model.flags model.registerModel)


viewLogin : Messages -> Model -> Html Msg
viewLogin texts model =
    Html.map LoginMsg (Page.Login.View2.view texts.login model.flags model.loginModel)


viewHome : Messages -> Model -> Html Msg
viewHome texts model =
    Html.map HomeMsg (Page.Home.View.view texts.home model.homeModel)


footer : Model -> Html Msg
footer model =
    let
        defaultFooter =
            div [ class styleFooter ]
                [ a
                    [ href "https://eikek.github.io/sharry"
                    , class S.link
                    ]
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
            div [ class styleFooter ]
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



--- Helpers


styleTopNav : String
styleTopNav =
    "top-0 fixed z-50 w-full flex flex-row justify-start shadow-sm h-12 bg-indigo-100 dark:bg-warmgray-900 text-gray-800 dark:text-warmgray-200 antialiased"


styleMain : String
styleMain =
    "mt-6 flex flex-grow flex-col w-full h-screen-12 overflow-y-hidden bg-white dark:bg-warmgray-800 text-gray-800 dark:text-warmgray-300 antialiased"


styleFooter : String
styleFooter =
    "py-1 text-xs items-center text-center"


dropdownLink : String
dropdownLink =
    "px-4 py-2 w-12 font-bold inline-flex h-full items-center hover:bg-indigo-200 dark:hover:bg-warmgray-800"


dropdownItem : String
dropdownItem =
    "transition-colors duration-200 items-center block px-4 py-2 text-normal hover:bg-gray-200 dark:hover:bg-warmgray-700 dark:hover:text-warmgray-50"


dropdownHeadItem : String
dropdownHeadItem =
    "transition-colors duration-200 items-center block px-4 py-2 font-semibold uppercase"


dropdownMenu : String
dropdownMenu =
    " absolute right-0 bg-white dark:bg-warmgray-800 border dark:border-warmgray-700 dark:text-warmgray-300 shadow-lg opacity-1 transition duration-200 min-w-max "
