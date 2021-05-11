module Page.NewInvite.View exposing (view)

import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Messages.NewInvitePage exposing (Texts)
import Page.NewInvite.Data exposing (..)
import Styles as S


view : Texts -> Flags -> Model -> Html Msg
view texts flags model =
    div [ class "container mx-auto flex flex-col px-2 sm:px-0 mt-2" ]
        [ div [ class "text-2xl font-bold" ]
            [ i [ class "fa fa-pencil-alt mr-2 mb-4" ]
                []
            , text texts.createNewTitle
            ]
        , div [ class "mb-4" ]
            [ inviteMessage texts flags
            ]
        , Html.form
            [ action "#"
            , autocomplete False
            , onSubmit GenerateInvite
            ]
            [ div [ class "flex flex-col" ]
                [ label
                    [ for "invitekey"
                    , class "mb-1 text-xs sm:text-sm tracking-wide "
                    ]
                    [ text texts.invitationKey
                    ]
                , div [ class "relative" ]
                    [ div
                        [ class "inline-flex items-center justify-center"
                        , class "absolute left-0 top-0 h-full w-10"
                        , class "text-gray-400 dark:text-bluegray-400"
                        ]
                        [ i [ class "fa fa-key" ] []
                        ]
                    , input
                        [ id "email"
                        , type_ "password"
                        , name "invitekey"
                        , autocomplete False
                        , onInput SetPassword
                        , value model.password
                        , autofocus True
                        , class ("pl-10 pr-4 py-2 rounded-lg" ++ S.textInput)
                        ]
                        []
                    ]
                ]
            , div [ class "flex flex-col my-3" ]
                [ div [ class "flex flex-row space-x-2" ]
                    [ button
                        [ type_ "submit"
                        , class (S.primaryButton ++ "inline-flex")
                        ]
                        [ text texts.submit
                        ]
                    , a
                        [ class S.secondaryButton
                        , href "#"
                        , onClick Reset
                        ]
                        [ text texts.reset
                        ]
                    ]
                ]
            , resultMessage texts model
            ]
        ]


resultMessage : Texts -> Model -> Html Msg
resultMessage texts model =
    div
        [ classList
            [ ( S.errorMessage, isFailed model.result )
            , ( S.successMessage, isSuccess model.result )
            , ( "hidden", model.result == Empty )
            ]
        ]
        [ case model.result of
            Failed err ->
                text err

            -- GenericFail m ->
            --     text m
            Success r ->
                div [ class "" ]
                    [ div [ class "text-xl mb-3" ]
                        [ text texts.success
                        , text ", "
                        , text texts.invitationKey
                        ]
                    , p
                        []
                        []
                    , pre [ class "text-center font-mono mt-4" ]
                        [ Maybe.withDefault "" r.key |> text
                        ]
                    ]

            Empty ->
                span [ class "hidden" ] []
        ]


view0 : Texts -> Flags -> Model -> Html Msg
view0 texts flags model =
    div [ class "newinvite-page" ]
        [ div [ class "ui text container" ]
            [ h1 [ class "ui cener aligned header" ]
                [ i [ class "pencil alternate icon" ] []
                , div [ class "content" ]
                    [ text texts.createNewTitle
                    ]
                ]
            , inviteMessage texts flags
            , Html.form
                [ classList
                    [ ( "ui large form raised segment", True )
                    , ( "error", isFailed model.result )
                    , ( "success", isSuccess model.result )
                    ]
                , onSubmit GenerateInvite
                ]
                [ div [ class "required field" ]
                    [ label [] [ text texts.newInvitePassword ]
                    , div [ class "ui left icon input" ]
                        [ input
                            [ type_ "password"
                            , onInput SetPassword
                            , value model.password
                            , autofocus True
                            ]
                            []
                        , i [ class "key icon" ] []
                        ]
                    ]
                , button
                    [ class "ui primary button"
                    , type_ "submit"
                    ]
                    [ text texts.submit
                    ]
                , a [ class "ui right floated button", href "", onClick Reset ]
                    [ text texts.reset
                    ]
                , resultMessage texts model
                ]
            ]
        ]


inviteMessage : Texts -> Flags -> Html Msg
inviteMessage texts flags =
    div
        [ class S.message
        , classList
            [ ( "hidden", flags.config.signupMode /= "invite" )
            ]
        ]
        (List.map (Html.map (\_ -> Reset)) texts.message)
