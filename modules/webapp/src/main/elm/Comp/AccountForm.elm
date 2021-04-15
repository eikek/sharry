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
import Comp.FixedDropdown
import Comp.PasswordInput
import Comp.YesNoDimmer
import Data.AccountState exposing (AccountState)
import Data.DropdownStyle as DS
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Messages.AccountForm exposing (Texts)
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
    , deleteConfirm : Comp.YesNoDimmer.Model
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
    , deleteConfirm = Comp.YesNoDimmer.emptyModel
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
    | DeleteConfirmMsg Comp.YesNoDimmer.Msg
    | RequestDelete


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
            let
                m =
                    Comp.YesNoDimmer.activate model.deleteConfirm
            in
            ( { model | deleteConfirm = m }, FormNone )

        DeleteConfirmMsg lmsg ->
            let
                ( m, confirmed ) =
                    Comp.YesNoDimmer.update lmsg model.deleteConfirm

                id =
                    Maybe.map .id model.existing
            in
            ( { model | deleteConfirm = m }
            , if confirmed then
                Maybe.map FormDelete id
                    |> Maybe.withDefault FormNone

              else
                FormNone
            )


view : Texts -> Model -> Html Msg
view texts model =
    div [ class "ui segments" ]
        [ Html.map DeleteConfirmMsg (Comp.YesNoDimmer.view texts.yesNo model.deleteConfirm)
        , Html.form [ class "ui form segment" ]
            [ div
                [ classList
                    [ ( "disabled field", True )
                    , ( "invisible", isCreate model )
                    ]
                ]
                [ label [] [ text texts.id ]
                , input
                    [ type_ "text"
                    , Maybe.map .id model.existing
                        |> Maybe.withDefault "-"
                        |> value
                    ]
                    []
                ]
            , div
                [ classList
                    [ ( "required field", True )
                    , ( "disabled", isModify model )
                    , ( "error", String.isEmpty model.loginField )
                    ]
                ]
                [ label [] [ text texts.login ]
                , input
                    [ type_ "text"
                    , value model.loginField
                    , onInput SetLogin
                    ]
                    []
                ]
            , div [ class "required field" ]
                [ label [] [ text texts.state ]
                , Html.map StateMsg
                    (Comp.FixedDropdown.viewStyled
                        { display = Data.AccountState.toString
                        , selectPlaceholder = texts.dropdown.select
                        , icon = \n -> Nothing
                        , style = DS.mainStyle
                        }
                        False
                        (Just model.stateField)
                        model.stateModel
                    )
                ]
            , div [ class "inline required field" ]
                [ div [ class "ui checkbox" ]
                    [ input
                        [ type_ "checkbox"
                        , onCheck (\_ -> ToggleAdmin)
                        , checked model.adminField
                        ]
                        []
                    , label [] [ text texts.admin ]
                    ]
                ]
            , div [ class "field" ]
                [ label [] [ text "E-Mail" ]
                , input
                    [ type_ "text"
                    , Maybe.withDefault "" model.emailField |> value
                    , onInput SetEmail
                    ]
                    []
                ]
            , div
                [ classList
                    [ ( "field", True )
                    , ( "error", isCreate model && model.passwordField == Nothing )
                    , ( "required", isCreate model )
                    , ( "disabled", not (isCreate model || isIntern model) )
                    ]
                ]
                [ label [] [ text texts.password ]
                , Html.map PasswordMsg
                    (Comp.PasswordInput.view model.passwordField
                        model.passwordModel
                    )
                ]
            ]
        , div [ class "ui secondary segment" ]
            [ button
                [ type_ "button"
                , class "ui primary button"
                , onClick Submit
                ]
                [ text texts.submit
                ]
            , button
                [ class "ui button"
                , type_ "button"
                , onClick Cancel
                ]
                [ text texts.back
                ]
            , button
                [ class "ui right floated red button"
                , classList
                    [ ( "hidden invisible", Maybe.map .id model.existing == Nothing )
                    ]
                , type_ "button"
                , onClick RequestDelete
                ]
                [ text texts.delete
                ]
            ]
        ]
