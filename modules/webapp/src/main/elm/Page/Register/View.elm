module Page.Register.View exposing (view)

import Comp.Basic as B
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Messages.RegisterPage exposing (Texts)
import Page exposing (Page(..))
import Page.Register.Data exposing (..)
import Styles as S


view : Texts -> Flags -> Model -> Html Msg
view texts flags model =
    div
        [ id "content"
        , class "h-full flex flex-col items-center justify-center w-full"
        , class S.content
        ]
        [ div [ class ("flex flex-col px-2 sm:px-4 py-4 rounded-md min-w-full md:min-w-0 md:w-96" ++ S.boxMd) ]
            [ div [ class "self-center" ]
                [ img
                    [ class "max-w-xs mx-auto max-h-20"
                    , src flags.config.iconUrl
                    ]
                    []
                ]
            , div [ class "text-4xl font-serif italic tracking-wider font-bold self-center my-2" ]
                [ text texts.signup
                ]
            , Html.form
                [ class "ui large error form raised segment"
                , onSubmit RegisterSubmit
                , autocomplete False
                ]
                [ div [ class "flex flex-col mt-6" ]
                    [ label
                        [ for "username"
                        , class S.inputLabel
                        ]
                        [ text texts.userLogin
                        , B.inputRequired
                        ]
                    , div [ class "relative" ]
                        [ div [ class S.inputIcon ]
                            [ i [ class "fa fa-user" ] []
                            ]
                        , input
                            [ type_ "text"
                            , name "collective"
                            , autocomplete False
                            , onInput SetLogin
                            , value model.login
                            , autofocus True
                            , class ("pl-10 pr-4 py-2 rounded-lg" ++ S.textInput)
                            , placeholder texts.userLogin
                            ]
                            []
                        ]
                    ]
                , div [ class "flex flex-col my-3" ]
                    [ label
                        [ for "passw1"
                        , class S.inputLabel
                        ]
                        [ text texts.password
                        , B.inputRequired
                        ]
                    , div [ class "relative" ]
                        [ div [ class S.inputIcon ]
                            [ i
                                [ class "fa"
                                , if model.showPass1 then
                                    class "fa-lock-open"

                                  else
                                    class "fa-lock"
                                ]
                                []
                            ]
                        , input
                            [ type_ <|
                                if model.showPass1 then
                                    "text"

                                else
                                    "password"
                            , name "passw1"
                            , autocomplete False
                            , onInput SetPass1
                            , value model.pass1
                            , class ("pl-10 pr-10 py-2 rounded-lg" ++ S.textInput)
                            , placeholder texts.password
                            ]
                            []
                        , a
                            [ class S.inputLeftIconLink
                            , onClick ToggleShowPass1
                            , href "#"
                            ]
                            [ i [ class "fa fa-eye" ] []
                            ]
                        ]
                    ]
                , div [ class "flex flex-col my-3" ]
                    [ label
                        [ for "passw2"
                        , class S.inputLabel
                        ]
                        [ text texts.passwordRepeat
                        , B.inputRequired
                        ]
                    , div [ class "relative" ]
                        [ div [ class S.inputIcon ]
                            [ i
                                [ class "fa"
                                , if model.showPass2 then
                                    class "fa-lock-open"

                                  else
                                    class "fa-lock"
                                ]
                                []
                            ]
                        , input
                            [ type_ <|
                                if model.showPass2 then
                                    "text"

                                else
                                    "password"
                            , name "passw2"
                            , autocomplete False
                            , onInput SetPass2
                            , value model.pass2
                            , class ("pl-10 pr-10 py-2 rounded-lg" ++ S.textInput)
                            , placeholder texts.passwordRepeat
                            ]
                            []
                        , a
                            [ class S.inputLeftIconLink
                            , onClick ToggleShowPass2
                            , href "#"
                            ]
                            [ i [ class "fa fa-eye" ] []
                            ]
                        ]
                    ]
                , div
                    [ class "flex flex-col my-3"
                    , classList [ ( "hidden", flags.config.signupMode /= "invite" ) ]
                    ]
                    [ label
                        [ for "invitekey"
                        , class S.inputLabel
                        ]
                        [ text texts.invitationKey
                        , B.inputRequired
                        ]
                    , div [ class "relative" ]
                        [ div [ class S.inputIcon ]
                            [ i [ class "fa fa-key" ] []
                            ]
                        , input
                            [ type_ "text"
                            , name "invitekey"
                            , autocomplete False
                            , onInput SetInvite
                            , model.invite |> Maybe.withDefault "" |> value
                            , class ("pl-10 pr-4 py-2 rounded-lg" ++ S.textInput)
                            , placeholder texts.invitationKey
                            ]
                            []
                        ]
                    ]
                , div [ class "flex flex-col my-3" ]
                    [ button
                        [ type_ "submit"
                        , class S.primaryButton
                        ]
                        [ text texts.submitButton
                        ]
                    ]
                , resultMessage texts model
                , renderLangAndSignin texts
                ]
            ]
        ]


renderLangAndSignin : Texts -> Html Msg
renderLangAndSignin texts =
    div [ class "flex flex-row mt-6 items-center" ]
        [ div
            [ class "flex flex-col flex-grow justify-end text-right text-sm opacity-75"
            ]
            [ span [ class "" ]
                [ text texts.alreadySignedUp
                ]
            , a
                [ class S.link
                , Page.href (LoginPage ( Nothing, False ))
                ]
                [ i [ class "fa fa-signin mr-1" ] []
                , text texts.signin
                ]
            ]
        ]


resultMessage : Texts -> Model -> Html Msg
resultMessage texts model =
    case model.result of
        Just r ->
            if r.success then
                div [ class S.successMessage ]
                    [ text texts.registrationSuccessful
                    ]

            else
                div [ class S.errorMessage ]
                    [ text r.message
                    ]

        Nothing ->
            if List.isEmpty model.errorMsg then
                span [ class "hidden" ] []

            else
                div [ class S.errorMessage ]
                    (List.map (\s -> div [] [ text s ]) model.errorMsg)
