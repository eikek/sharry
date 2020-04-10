module Page.Register.View exposing (view)

import Comp.LanguageChoose
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Messages.RegisterPage exposing (Texts)
import Page exposing (Page(..))
import Page.Register.Data exposing (..)


view : Texts -> Flags -> Model -> Html Msg
view texts flags model =
    div [ class "register-page" ]
        [ div [ class "ui centered grid" ]
            [ div [ class "row" ]
                [ div [ class "six wide column ui segment register-view" ]
                    [ h1 [ class "ui cener aligned icon header" ]
                        [ img
                            [ class "ui logo image"
                            , src flags.config.logoUrl
                            ]
                            []
                        , div [ class "content" ]
                            [ text texts.signup
                            ]
                        ]
                    , Html.form
                        [ class "ui large error form raised segment"
                        , onSubmit RegisterSubmit
                        , autocomplete False
                        ]
                        [ div [ class "required field" ]
                            [ label [] [ text texts.userLogin ]
                            , div [ class "ui left icon input" ]
                                [ input
                                    [ type_ "text"
                                    , autocomplete False
                                    , onInput SetLogin
                                    , value model.login
                                    ]
                                    []
                                , i [ class "user icon" ] []
                                ]
                            ]
                        , div
                            [ class "required field"
                            ]
                            [ label [] [ text texts.password ]
                            , div [ class "ui left icon action input" ]
                                [ input
                                    [ type_ <|
                                        if model.showPass1 then
                                            "text"

                                        else
                                            "password"
                                    , autocomplete False
                                    , onInput SetPass1
                                    , value model.pass1
                                    ]
                                    []
                                , i [ class "lock icon" ] []
                                , button [ class "ui icon button", onClick ToggleShowPass1 ]
                                    [ i [ class "eye icon" ] []
                                    ]
                                ]
                            ]
                        , div
                            [ class "required field"
                            ]
                            [ label [] [ text texts.passwordRepeat ]
                            , div [ class "ui left icon action input" ]
                                [ input
                                    [ type_ <|
                                        if model.showPass2 then
                                            "text"

                                        else
                                            "password"
                                    , autocomplete False
                                    , onInput SetPass2
                                    , value model.pass2
                                    ]
                                    []
                                , i [ class "lock icon" ] []
                                , button [ class "ui icon button", onClick ToggleShowPass2 ]
                                    [ i [ class "eye icon" ] []
                                    ]
                                ]
                            ]
                        , div
                            [ classList
                                [ ( "field", True )
                                , ( "invisible", flags.config.signupMode /= "invite" )
                                ]
                            ]
                            [ label [] [ text texts.invitationKey ]
                            , div [ class "ui left icon input" ]
                                [ input
                                    [ type_ "text"
                                    , autocomplete False
                                    , onInput SetInvite
                                    , model.invite |> Maybe.withDefault "" |> value
                                    ]
                                    []
                                , i [ class "key icon" ] []
                                ]
                            ]
                        , button
                            [ class "ui primary button"
                            , type_ "submit"
                            ]
                            [ text texts.submitButton
                            ]
                        ]
                    , resultMessage texts model
                    , renderLanguageAndSignin texts
                    ]
                ]
            ]
        ]


renderLanguageAndSignin : Texts -> Html Msg
renderLanguageAndSignin texts =
    div [ class "ui two column stackable grid basic segment" ]
        [ div [ class "column" ]
            [ Comp.LanguageChoose.linkList SetLanguage
            ]
        , div [ class "right aligned column" ]
            [ text (texts.alreadySignedUp ++ " ")
            , a [ class "ui link", Page.href (LoginPage ( Nothing, False )) ]
                [ i [ class "sign-in icon" ] []
                , text texts.signin
                ]
            ]
        ]


resultMessage : Texts -> Model -> Html Msg
resultMessage texts model =
    case model.result of
        Just r ->
            if r.success then
                div [ class "ui success message" ]
                    [ text texts.registrationSuccessful
                    ]

            else
                div [ class "ui error message" ]
                    [ text r.message
                    ]

        Nothing ->
            if List.isEmpty model.errorMsg then
                span [ class "invisible" ] []

            else
                div [ class "ui error message" ]
                    (List.map (\s -> div [] [ text s ]) model.errorMsg)
