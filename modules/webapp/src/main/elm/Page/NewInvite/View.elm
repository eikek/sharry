module Page.NewInvite.View exposing (view)

import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Messages exposing (Messages)
import Page.NewInvite.Data exposing (..)


view : Messages -> Flags -> Model -> Html Msg
view texts flags model =
    div [ class "newinvite-page" ]
        [ div [ class "ui text container" ]
            [ h1 [ class "ui cener aligned header" ]
                [ i [ class "pencil alternate icon" ] []
                , div [ class "content" ]
                    [ text "Create new invitations"
                    ]
                ]
            , inviteMessage flags
            , Html.form
                [ classList
                    [ ( "ui large form raised segment", True )
                    , ( "error", isFailed model.result )
                    , ( "success", isSuccess model.result )
                    ]
                , onSubmit GenerateInvite
                ]
                [ div [ class "required field" ]
                    [ label [] [ text "New Invitation Password" ]
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
                    [ text "Submit"
                    ]
                , a [ class "ui right floated button", href "", onClick Reset ]
                    [ text "Reset"
                    ]
                , resultMessage model
                ]
            ]
        ]


resultMessage : Model -> Html Msg
resultMessage model =
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
                    [ div [ class "header" ] [ text "Error" ]
                    , p [] [ text m ]
                    ]

            Success r ->
                div [ class "content" ]
                    [ div [ class "header" ] [ text "Success" ]
                    , p [] [ text r.message ]
                    , p [] [ text "Invitation Key:" ]
                    , pre []
                        [ Maybe.withDefault "" r.key |> text
                        ]
                    ]

            Empty ->
                span [] []
        ]


inviteMessage : Flags -> Html Msg
inviteMessage flags =
    div
        [ classList
            [ ( "ui message", True )
            , ( "hidden", flags.config.signupMode /= "invite" )
            ]
        ]
        [ p []
            [ text
                """Sharry requires an invite when signing up. You can
             create these invites here and send them to friends so
             they can signup with Sharry."""
            ]
        , p []
            [ text
                """Each invite can only be used once. You'll need to
             create one key for each person you want to invite."""
            ]
        , p []
            [ text
                """Creating an invite requires providing the password
             from the configuration."""
            ]
        ]
