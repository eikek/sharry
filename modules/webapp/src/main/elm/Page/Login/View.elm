module Page.Login.View exposing (view)

import Api
import Api.Model.OAuthItem exposing (OAuthItem)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Markdown
import Messages exposing (Messages)
import Page exposing (Page(..))
import Page.Login.Data exposing (..)


view : Flags -> Model -> Html Msg
view flags model =
    let
        texts =
            Messages.fromFlags flags
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
                        renderOAuthButtons flags model
                    , resultMessage texts model
                    , renderLangAndSignup flags model
                    ]
                ]
            , renderWelcome flags
            ]
        ]


renderLangAndSignup : Flags -> Model -> Html Msg
renderLangAndSignup flags model =
    let
        texts =
            Messages.fromFlags flags

        renderFlag lang =
            a
                [ class "item"
                , href "#"
                , onClick (SetLanguage lang)
                , title (Messages.get lang |> .label)
                ]
                [ i [ Messages.get lang |> .flagIcon |> class ] []
                ]
    in
    div [ class "ui two column stackable grid basic segment" ]
        [ div [ class "column" ]
            [ div [ class "ui mini horizontal divided link list" ]
                (List.map renderFlag Messages.allLanguages)
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


renderOAuthButtons : Flags -> Model -> Html Msg
renderOAuthButtons flags model =
    div [ class "ui very basic segment" ]
        [ div [ class "ui horizontal divider" ] [ text "Or" ]
        , div [ class "ui buttons" ]
            (List.map (renderOAuthButton flags) flags.config.oauthConfig)
        ]


renderOAuthButton : Flags -> OAuthItem -> Html Msg
renderOAuthButton flags item =
    let
        texts =
            Messages.fromFlags flags

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
        , text (texts.loginVia ++ " ")
        , text item.name
        ]


resultMessage : Messages -> Model -> Html Msg
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
