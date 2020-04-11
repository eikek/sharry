module Page.Login.View exposing (view)

import Api
import Api.Model.OAuthItem exposing (OAuthItem)
import Comp.LanguageChoose
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Markdown
import Messages exposing (Language)
import Messages.LoginPage exposing (Texts)
import Page exposing (Page(..))
import Page.Login.Data exposing (..)


view : Texts -> Flags -> Model -> Html Msg
view texts flags model =
    let
        currentLanguage =
            Messages.fromFlags flags
                |> .lang
    in
    div [ class "login-page" ]
        [ div [ class "ui centered grid" ]
            [ div [ class "row" ]
                [ div [ class "six wide column ui segment login-view" ]
                    [ h1 [ class "ui center aligned icon header" ]
                        [ img
                            [ class "ui logo image"
                            , src flags.config.logoUrl
                            ]
                            []
                        ]
                    , Html.form
                        [ class "ui large error raised form segment"
                        , onSubmit Authenticate
                        , autocomplete False
                        ]
                        [ div [ class "field" ]
                            [ label [] [ text texts.username ]
                            , div [ class "ui left icon input" ]
                                [ input
                                    [ type_ "text"
                                    , autocomplete False
                                    , onInput SetUsername
                                    , value model.username
                                    , placeholder texts.loginPlaceholder
                                    , autofocus True
                                    ]
                                    []
                                , i [ class "user icon" ] []
                                ]
                            ]
                        , div [ class "field" ]
                            [ label [] [ text texts.password ]
                            , div [ class "ui left icon input" ]
                                [ input
                                    [ type_ "password"
                                    , autocomplete False
                                    , onInput SetPassword
                                    , value model.password
                                    , placeholder texts.passwordPlaceholder
                                    ]
                                    []
                                , i [ class "lock icon" ] []
                                ]
                            ]
                        , button
                            [ class "ui primary fluid button"
                            , type_ "submit"
                            ]
                            [ text texts.loginButton
                            ]
                        ]
                    , if List.isEmpty flags.config.oauthConfig then
                        div [] []

                      else
                        renderOAuthButtons texts flags model
                    , resultMessage texts model
                    , renderLangAndSignup currentLanguage texts flags model
                    ]
                ]
            , renderWelcome flags
            ]
        ]


renderLangAndSignup : Language -> Texts -> Flags -> Model -> Html Msg
renderLangAndSignup current texts flags model =
    div [ class "ui two column stackable grid basic segment" ]
        [ div [ class "column language" ]
            [ Html.map LangChooseMsg
                (Comp.LanguageChoose.view
                    texts.dropdown
                    current
                    model.langChoose
                )
            ]
        , div
            [ classList
                [ ( "right aligned column", True )
                , ( "invisible hidden", flags.config.signupMode == "closed" )
                ]
            ]
            [ text (texts.noAccount ++ " ")
            , a [ class "ui icon link", Page.href RegisterPage ]
                [ i [ class "edit icon" ] []
                , text texts.signupLink
                ]
            ]
        ]


renderWelcome : Flags -> Html Msg
renderWelcome flags =
    case flags.config.welcomeMessage of
        "" ->
            span [ class "hidden invisible" ] []

        msg ->
            div [ class "row" ]
                [ div [ class "six wide column ui segment" ]
                    [ Markdown.toHtml [] msg
                    ]
                ]


renderOAuthButtons : Texts -> Flags -> Model -> Html Msg
renderOAuthButtons texts flags model =
    div [ class "ui very basic segment" ]
        [ div [ class "ui horizontal divider" ] [ text "Or" ]
        , div [ class "ui buttons" ]
            (List.map (renderOAuthButton texts flags) flags.config.oauthConfig)
        ]


renderOAuthButton : Texts -> Flags -> OAuthItem -> Html Msg
renderOAuthButton texts flags item =
    let
        icon =
            "ui icon " ++ Maybe.withDefault "user outline" item.icon

        url =
            Api.oauthUrl flags item
    in
    a
        [ class "ui basic primary button"
        , href url
        ]
        [ i [ class icon ] []
        , text (texts.via ++ " ")
        , text item.name
        ]


resultMessage : Texts -> Model -> Html Msg
resultMessage texts model =
    case model.result of
        Just r ->
            if r.success then
                div [ class "ui success message" ]
                    [ text texts.loginSuccessful
                    ]

            else
                div [ class "ui error message" ]
                    [ text r.message
                    ]

        Nothing ->
            span [] []
