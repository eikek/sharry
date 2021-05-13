module Page.Settings.View exposing (view)

import Comp.Basic as B
import Comp.MenuBar as MB
import Comp.PasswordInput
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Messages.SettingsPage exposing (Texts)
import Page.Settings.Data exposing (Model, Msg(..))
import Styles as S


view : Texts -> Model -> Html Msg
view texts model =
    div
        [ class S.content
        , class "flex flex-col"
        ]
        [ h1 [ class S.header1 ]
            [ i [ class "fa fa-cog mr-2" ] []
            , text texts.settingsTitle
            ]
        , banner model
        , emailForm texts model
        , changePasswordForm texts model
        ]


emailForm : Texts -> Model -> Html Msg
emailForm texts model =
    div [ class "flex flex-col mb-2" ]
        [ h2 [ class S.header2 ]
            [ text texts.changeMailHeader
            ]
        , Html.form [ class "" ]
            [ div [ class "mb-2" ]
                [ label [ class S.inputLabel ]
                    [ text texts.newEmail
                    ]
                , input
                    [ type_ "text"
                    , placeholder texts.newEmailPlaceholder
                    , onInput SetEmail
                    , Maybe.withDefault "" model.emailField
                        |> value
                    , class S.textInput
                    ]
                    []
                , span [ class "text-sm opacity-70" ]
                    [ text texts.submitEmptyMailInfo
                    ]
                ]
            , div [ class "flex flex-row" ]
                [ MB.viewItem <|
                    MB.PrimaryButton
                        { label = texts.submit
                        , icon = Just "fa fa-save"
                        , title = texts.submit
                        , tagger = SubmitEmail
                        }
                ]
            ]
        ]


changePasswordForm : Texts -> Model -> Html Msg
changePasswordForm texts model =
    div
        [ classList
            [ ( "invisible", model.passwordAvailable == Just False )
            ]
        , class "flex flex-col"
        ]
        [ B.loadingDimmer
            { active = model.passwordAvailable == Nothing
            , label = ""
            }
        , h2 [ class S.header2 ]
            [ text texts.changePasswordHeader
            ]
        , Html.form [ class "" ]
            [ div [ class "mb-4" ]
                [ label [ class S.inputLabel ]
                    [ text texts.currentPassword
                    , B.inputRequired
                    ]
                , Html.map SetOldPassword
                    (Comp.PasswordInput.view
                        { placeholder = "" }
                        model.oldPasswordField
                        False
                        model.oldPasswordModel
                    )
                ]
            , div [ class "mb-4" ]
                [ label [ class S.inputLabel ]
                    [ text texts.newPassword
                    , B.inputRequired
                    ]
                , Html.map SetNewPassword1
                    (Comp.PasswordInput.view
                        { placeholder = "" }
                        model.newPasswordField1
                        False
                        model.newPasswordModel1
                    )
                ]
            , div [ class "" ]
                [ label [ class S.inputLabel ]
                    [ text texts.newPasswordRepeat
                    , B.inputRequired
                    ]
                , Html.map SetNewPassword2
                    (Comp.PasswordInput.view
                        { placeholder = "" }
                        model.newPasswordField2
                        False
                        model.newPasswordModel2
                    )
                ]
            ]
        , div [ class "flex flex-row" ]
            [ MB.viewItem <|
                MB.PrimaryButton
                    { label = texts.submit
                    , icon = Just "fa fa-save"
                    , title = texts.submit
                    , tagger = SubmitPassword
                    }
            ]
        ]


banner : Model -> Html Msg
banner model =
    div
        [ classList
            [ ( "hidden", model.banner == Nothing )
            , ( S.errorMessage, Maybe.map .success model.banner == Just False )
            , ( S.successMessage, Maybe.map .success model.banner == Just True )
            ]
        ]
        [ Maybe.map .text model.banner
            |> Maybe.withDefault ""
            |> text
        ]
