module Page.Settings.View exposing (view)

import Comp.PasswordInput
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Messages.SettingsPage exposing (Texts)
import Page.Settings.Data exposing (Model, Msg(..))


view : Texts -> Model -> Html Msg
view texts model =
    div [ class "ui text container account-page" ]
        [ h1 [ class "ui dividing header" ]
            [ i [ class "ui cog icon" ] []
            , text texts.settingsTitle
            ]
        , banner model
        , emailForm texts model
        , changePasswordForm texts model
        ]


emailForm : Texts -> Model -> Html Msg
emailForm texts model =
    div [ class "ui segments" ]
        [ div [ class "ui segment" ]
            [ h2 [ class "ui header" ]
                [ text texts.changeMailHeader
                ]
            , Html.form [ class "ui form" ]
                [ div [ class "ui field" ]
                    [ label [] [ text texts.newEmail ]
                    , input
                        [ type_ "text"
                        , placeholder texts.newEmailPlaceholder
                        , onInput SetEmail
                        , Maybe.withDefault "" model.emailField
                            |> value
                        ]
                        []
                    ]
                , p []
                    [ text texts.submitEmptyMailInfo
                    ]
                ]
            ]
        , div [ class "ui secondary segment" ]
            [ button
                [ type_ "button"
                , class "ui primary button"
                , onClick SubmitEmail
                ]
                [ text texts.submit
                ]
            ]
        ]


changePasswordForm : Texts -> Model -> Html Msg
changePasswordForm texts model =
    div [ class "ui segments" ]
        [ div [ class "ui segment" ]
            [ h2 [ class "ui header" ]
                [ text texts.changePasswordHeader
                ]
            , Html.form [ class "ui form" ]
                [ div [ class "ui required field" ]
                    [ label [] [ text texts.currentPassword ]
                    , Html.map SetOldPassword
                        (Comp.PasswordInput.view
                            model.oldPasswordField
                            model.oldPasswordModel
                        )
                    ]
                , div [ class "ui required field" ]
                    [ label [] [ text texts.newPassword ]
                    , Html.map SetNewPassword1
                        (Comp.PasswordInput.view
                            model.newPasswordField1
                            model.newPasswordModel1
                        )
                    ]
                , div [ class "ui required field" ]
                    [ label [] [ text texts.newPasswordRepeat ]
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
                [ text texts.submit
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
