module Page.Login.View exposing (view)

import Api
import Api.Model.OAuthItem exposing (OAuthItem)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Page exposing (Page(..))
import Page.Login.Data exposing (..)


view : Flags -> Model -> Html Msg
view flags model =
    div [ class "login-page" ]
        [ div [ class "ui centered grid" ]
            [ div [ class "row" ]
                [ div [ class "six wide column ui segment login-view" ]
                    [ h1 [ class "ui center aligned icon header" ]
                        [ img
                            [ class "ui logo image"
                            , src (flags.config.assetsPath ++ "/img/logo.png")
                            ]
                            []
                        ]
                    , Html.form
                        [ class "ui large error raised form segment"
                        , onSubmit Authenticate
                        , autocomplete False
                        ]
                        [ div [ class "field" ]
                            [ label [] [ text "Username" ]
                            , div [ class "ui left icon input" ]
                                [ input
                                    [ type_ "text"
                                    , autocomplete False
                                    , onInput SetUsername
                                    , value model.username
                                    , placeholder "Login"
                                    , autofocus True
                                    ]
                                    []
                                , i [ class "user icon" ] []
                                ]
                            ]
                        , div [ class "field" ]
                            [ label [] [ text "Password" ]
                            , div [ class "ui left icon input" ]
                                [ input
                                    [ type_ "password"
                                    , autocomplete False
                                    , onInput SetPassword
                                    , value model.password
                                    , placeholder "Password"
                                    ]
                                    []
                                , i [ class "lock icon" ] []
                                ]
                            ]
                        , button
                            [ class "ui primary fluid button"
                            , type_ "submit"
                            ]
                            [ text "Login"
                            ]
                        ]
                    , if List.isEmpty flags.config.oauthConfig then
                        div [] []

                      else
                        renderOAuthButtons flags model
                    , resultMessage model
                    , div [ class "ui very basic right aligned segment" ]
                        [ text "No account? "
                        , a [ class "ui icon link", Page.href RegisterPage ]
                            [ i [ class "edit icon" ] []
                            , text "Sign up!"
                            ]
                        ]
                    ]
                ]
            ]
        ]


renderOAuthButtons : Flags -> Model -> Html Msg
renderOAuthButtons flags model =
    div []
        [ div [ class "ui horizontal divider" ] [ text "Or" ]
        , div [ class "ui buttons" ]
            (List.map (renderOAuthButton flags) flags.config.oauthConfig)
        ]


renderOAuthButton : Flags -> OAuthItem -> Html Msg
renderOAuthButton flags item =
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
        , text "via "
        , text item.name
        ]


resultMessage : Model -> Html Msg
resultMessage model =
    case model.result of
        Just r ->
            if r.success then
                div [ class "ui success message" ]
                    [ text "Login successful."
                    ]

            else
                div [ class "ui error message" ]
                    [ text r.message
                    ]

        Nothing ->
            span [] []
