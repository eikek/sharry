module Page.Settings.View exposing (view)

import Comp.PasswordInput
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Page.Settings.Data exposing (Model, Msg(..))


view : Model -> Html Msg
view model =
    div [ class "ui text container account-page" ]
        [ h1 [ class "ui dividing header" ]
            [ i [ class "ui cog icon" ] []
            , text "Settings"
            ]
        , banner model
        , emailForm model
        , changePasswordForm model
        ]


emailForm : Model -> Html Msg
emailForm model =
    div [ class "ui segments" ]
        [ div [ class "ui segment" ]
            [ h2 [ class "ui header" ]
                [ text "Change your E-Mail"
                ]
            , Html.form [ class "ui form" ]
                [ div [ class "ui field" ]
                    [ label [] [ text "New E-Mail" ]
                    , input
                        [ type_ "text"
                        , placeholder "E-Mail address"
                        , onInput SetEmail
                        , Maybe.withDefault "" model.emailField
                            |> value
                        ]
                        []
                    ]
                , p []
                    [ text "Submitting an empty form deletes the E-Mail address."
                    ]
                ]
            ]
        , div [ class "ui secondary segment" ]
            [ button
                [ type_ "button"
                , class "ui primary button"
                , onClick SubmitEmail
                ]
                [ text "Submit"
                ]
            ]
        ]


changePasswordForm : Model -> Html Msg
changePasswordForm model =
    div [ class "ui segments" ]
        [ div [ class "ui segment" ]
            [ h2 [ class "ui header" ]
                [ text "Change Password"
                ]
            , Html.form [ class "ui form" ]
                [ div [ class "ui required field" ]
                    [ label [] [ text "Current Password" ]
                    , Html.map SetOldPassword
                        (Comp.PasswordInput.view
                            model.oldPasswordField
                            model.oldPasswordModel
                        )
                    ]
                , div [ class "ui required field" ]
                    [ label [] [ text "New Password" ]
                    , Html.map SetNewPassword1
                        (Comp.PasswordInput.view
                            model.newPasswordField1
                            model.newPasswordModel1
                        )
                    ]
                , div [ class "ui required field" ]
                    [ label [] [ text "New Password (Repeat)" ]
                    , Html.map SetNewPassword2
                        (Comp.PasswordInput.view
                            model.newPasswordField2
                            model.newPasswordModel2
                        )
                    ]
                ]
            ]
        , div [ class "ui secondary segment" ]
            [ button
                [ type_ "button"
                , class "ui primary button"
                , onClick SubmitPassword
                ]
                [ text "Submit"
                ]
            ]
        ]


banner : Model -> Html Msg
banner model =
    div
        [ classList
            [ ( "ui message", True )
            , ( "hidden invisible", model.banner == Nothing )
            , ( "error", Maybe.map .success model.banner == Just False )
            , ( "success", Maybe.map .success model.banner == Just True )
            ]
        ]
        [ Maybe.map .text model.banner
            |> Maybe.withDefault ""
            |> text
        ]
