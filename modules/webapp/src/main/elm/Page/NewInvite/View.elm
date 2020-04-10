module Page.NewInvite.View exposing (view)

import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Messages.NewInvitePage exposing (Texts)
import Page.NewInvite.Data exposing (..)


view : Texts -> Flags -> Model -> Html Msg
view texts flags model =
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


resultMessage : Texts -> Model -> Html Msg
resultMessage texts model =
    div
        [ classList
            [ ( "ui message", True )
            , ( "error", isFailed model.result )
            , ( "success", isSuccess model.result )
            , ( "hidden", model.result == Empty )
            ]
        ]
        [ case model.result of
            Failed m ->
                div [ class "content" ]
                    [ div [ class "header" ] [ text texts.error ]
                    , p [] [ text m ]
                    ]

            Success r ->
                div [ class "content" ]
                    [ div [ class "header" ] [ text texts.success ]
                    , p [] [ text r.message ]
                    , p [] [ text texts.invitationKey ]
                    , pre []
                        [ Maybe.withDefault "" r.key |> text
                        ]
                    ]

            Empty ->
                span [] []
        ]


inviteMessage : Texts -> Flags -> Html Msg
inviteMessage texts flags =
    div
        [ classList
            [ ( "ui message", True )
            , ( "hidden", flags.config.signupMode /= "invite" )
            ]
        ]
        (List.map (Html.map (\_ -> Reset)) texts.message)
