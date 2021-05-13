module Comp.AccountForm exposing
    ( FormAction(..)
    , Model
    , Msg
    , init
    , initModify
    , initNew
    , update
    , view
    )

import Api.Model.AccountCreate exposing (AccountCreate)
import Api.Model.AccountDetail exposing (AccountDetail)
import Api.Model.AccountModify exposing (AccountModify)
import Comp.Basic as B
import Comp.ConfirmModal
import Comp.FixedDropdown
import Comp.MenuBar as MB
import Comp.PasswordInput
import Data.AccountState exposing (AccountState)
import Data.DropdownStyle as DS
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Messages.AccountForm exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { existing : Maybe AccountDetail
    , loginField : String
    , emailField : Maybe String
    , passwordModel : Comp.PasswordInput.Model
    , passwordField : Maybe String
    , stateModel : Comp.FixedDropdown.Model AccountState
    , stateField : AccountState
    , adminField : Bool
    , deleteRequested : Bool
    }


init : Maybe AccountDetail -> Model
init ma =
    Maybe.map initModify ma
        |> Maybe.withDefault initNew


initNew : Model
initNew =
    { existing = Nothing
    , loginField = ""
    , emailField = Nothing
    , passwordModel = Comp.PasswordInput.init
    , passwordField = Nothing
    , stateModel = Comp.FixedDropdown.init Data.AccountState.all
    , stateField = Data.AccountState.Active
    , adminField = False
    , deleteRequested = False
    }


initModify : AccountDetail -> Model
initModify acc =
    { initNew
        | existing = Just acc
        , loginField = acc.login
        , emailField = acc.email
        , stateField =
            Data.AccountState.fromStringOrActive acc.state
        , adminField = acc.admin
    }


type Msg
    = SetLogin String
    | SetEmail String
    | PasswordMsg Comp.PasswordInput.Msg
    | StateMsg (Comp.FixedDropdown.Msg AccountState)
    | ToggleAdmin
    | Cancel
    | Submit
    | RequestDelete
    | DeleteConfirm
    | DeleteCancel


type FormAction
    = FormModified String AccountModify
    | FormCreated AccountCreate
    | FormCancelled
    | FormNone
    | FormDelete String


isCreate : Model -> Bool
isCreate model =
    model.existing == Nothing


isModify : Model -> Bool
isModify model =
    not (isCreate model)


isIntern : Model -> Bool
isIntern model =
    Maybe.map .source model.existing
        |> Maybe.map ((==) "intern")
        |> Maybe.withDefault False


formInvalid : Model -> Bool
formInvalid model =
    String.isEmpty model.loginField
        || (isCreate model && model.passwordField == Nothing)


update : Msg -> Model -> ( Model, FormAction )
update msg model =
    case msg of
        SetLogin str ->
            ( { model | loginField = str }, FormNone )

        SetEmail str ->
            ( { model
                | emailField = Util.Maybe.fromString str
              }
            , FormNone
            )

        PasswordMsg lmsg ->
            let
                ( m, pw ) =
                    Comp.PasswordInput.update lmsg model.passwordModel
            in
            ( { model
                | passwordModel = m
                , passwordField = pw
              }
            , FormNone
            )

        StateMsg lmsg ->
            let
                ( m, sel ) =
                    Comp.FixedDropdown.update lmsg model.stateModel
            in
            ( { model
                | stateModel = m
                , stateField =
                    Maybe.withDefault model.stateField sel
              }
            , FormNone
            )

        ToggleAdmin ->
            ( { model | adminField = not model.adminField }
            , FormNone
            )

        Cancel ->
            ( model, FormCancelled )

        Submit ->
            if formInvalid model then
                ( model, FormNone )

            else
                case Maybe.map .id model.existing of
                    Just id ->
                        ( model
                        , FormModified id
                            { state = Data.AccountState.toString model.stateField
                            , admin = model.adminField
                            , email = model.emailField
                            , password = model.passwordField
                            }
                        )

                    Nothing ->
                        ( model
                        , FormCreated
                            { login = model.loginField
                            , state = Data.AccountState.toString model.stateField
                            , admin = model.adminField
                            , email = model.emailField
                            , password = Maybe.withDefault "" model.passwordField
                            }
                        )

        RequestDelete ->
            ( { model | deleteRequested = True }, FormNone )

        DeleteConfirm ->
            ( { model | deleteRequested = False }
            , Maybe.map .id model.existing
                |> Maybe.map FormDelete
                |> Maybe.withDefault FormNone
            )

        DeleteCancel ->
            ( { model | deleteRequested = False }, FormNone )



--- View


view : Texts -> Model -> Html Msg
view texts model =
    let
        modalSettings =
            Comp.ConfirmModal.defaultSettings
                DeleteConfirm
                DeleteCancel
                texts.yesNo.confirmButton
                texts.yesNo.cancelButton
                texts.yesNo.message
    in
    div [ class "flex flex-col relative" ]
        [ Comp.ConfirmModal.view { modalSettings | enabled = model.deleteRequested }
        , Html.form [ class "" ]
            [ div
                [ class "mb-4"
                ]
                [ label
                    [ class S.inputLabel
                    ]
                    [ text texts.login
                    , B.inputRequired
                    ]
                , input
                    [ type_ "text"
                    , disabled (isModify model)
                    , value model.loginField
                    , if isModify model then
                        class "disabled"

                      else
                        onInput SetLogin
                    , class S.textInput
                    , classList
                        [ ( S.inputErrorBorder, String.isEmpty model.loginField )
                        ]
                    ]
                    []
                ]
            , div [ class "mb-4" ]
                [ label
                    [ class S.inputLabel
                    ]
                    [ text texts.state
                    , B.inputRequired
                    ]
                , Html.map StateMsg
                    (Comp.FixedDropdown.viewStyled
                        { display = Data.AccountState.toString
                        , selectPlaceholder = texts.dropdown.select
                        , icon = \_ -> Nothing
                        , style = DS.mainStyle
                        }
                        False
                        (Just model.stateField)
                        model.stateModel
                    )
                ]
            , div [ class "mb-4" ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { id = "is-admin"
                        , value = model.adminField
                        , tagger = \_ -> ToggleAdmin
                        , label = texts.admin
                        }
                ]
            , div [ class "mb-4" ]
                [ label [ class S.inputLabel ]
                    [ text texts.email
                    ]
                , input
                    [ type_ "text"
                    , Maybe.withDefault "" model.emailField |> value
                    , onInput SetEmail
                    , class S.textInput
                    ]
                    []
                ]
            , div
                [ class "mb-4"
                , classList
                    [ ( "hidden", not (isCreate model || isIntern model) )
                    ]
                ]
                [ label [ class S.inputLabel ]
                    [ text texts.password
                    , if isCreate model then
                        B.inputRequired

                      else
                        span [ class "hidden" ] []
                    ]
                , Html.map PasswordMsg
                    (Comp.PasswordInput.view
                        { placeholder = "" }
                        model.passwordField
                        (isCreate model && model.passwordField == Nothing)
                        model.passwordModel
                    )
                ]
            ]
        , MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = Submit
                    , title = texts.submit
                    , icon = Just "fa fa-save"
                    , label = texts.submit
                    }
                , MB.SecondaryButton
                    { tagger = Cancel
                    , title = texts.back
                    , label = texts.back
                    , icon = Just "fa fa-arrow-left"
                    }
                ]
            , end =
                [ MB.CustomButton
                    { tagger = RequestDelete
                    , label = texts.delete
                    , title = texts.delete
                    , icon = Just "fa fa-trash"
                    , inputClass =
                        [ ( "hidden", Maybe.map .id model.existing == Nothing )
                        , ( S.deleteButton, True )
                        ]
                    }
                ]
            , rootClasses = ""
            }
        ]
