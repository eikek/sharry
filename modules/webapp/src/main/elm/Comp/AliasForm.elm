module Comp.AliasForm exposing
    ( FormAction(..)
    , Model
    , Msg
    , init
    , initModify
    , initNew
    , update
    , view
    )

import Api.Model.AliasChange exposing (AliasChange)
import Api.Model.AliasDetail exposing (AliasDetail)
import Comp.Basic as B
import Comp.ConfirmModal
import Comp.MenuBar as MB
import Comp.ValidityField
import Data.Flags exposing (Flags)
import Data.ValidityValue exposing (ValidityValue(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Messages.AliasForm exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { existing : Maybe AliasDetail
    , nameField : String
    , idField : Maybe String
    , validityModel : Comp.ValidityField.Model
    , validityField : ValidityValue
    , enabledField : Bool
    , deleteRequested : Bool
    }


init : Flags -> Maybe AliasDetail -> Model
init flags ma =
    Maybe.map (initModify flags) ma
        |> Maybe.withDefault (initNew flags)


initNew : Flags -> Model
initNew flags =
    { existing = Nothing
    , idField = Nothing
    , nameField = ""
    , validityModel = Comp.ValidityField.init flags
    , validityField = Data.ValidityValue.Days 2
    , enabledField = True
    , deleteRequested = False
    }


initModify : Flags -> AliasDetail -> Model
initModify flags alias_ =
    let
        m =
            initNew flags
    in
    { m
        | existing = Just alias_
        , idField = Just alias_.id
        , nameField = alias_.name
        , validityField = Data.ValidityValue.Millis alias_.validity
        , enabledField = alias_.enabled
    }


type Msg
    = SetName String
    | SetId String
    | ValidityMsg Comp.ValidityField.Msg
    | ToggleEnabled
    | Cancel
    | Submit
    | RequestDelete
    | DeleteConfirm
    | DeleteCancel


type FormAction
    = FormModified String AliasChange
    | FormCreated AliasChange
    | FormCancelled
    | FormDelete String
    | FormNone


isCreate : Model -> Bool
isCreate model =
    model.existing == Nothing


formInvalid : Model -> Bool
formInvalid model =
    Util.Maybe.fromString model.nameField == Nothing



--- Update


update : Msg -> Model -> ( Model, FormAction )
update msg model =
    case msg of
        SetName str ->
            ( { model | nameField = str }, FormNone )

        SetId str ->
            ( { model | idField = Util.Maybe.fromString str }, FormNone )

        ValidityMsg lmsg ->
            let
                ( m, sel ) =
                    Comp.ValidityField.update lmsg model.validityModel
            in
            ( { model
                | validityModel = m
                , validityField = Maybe.withDefault model.validityField sel
              }
            , FormNone
            )

        ToggleEnabled ->
            ( { model | enabledField = not model.enabledField }
            , FormNone
            )

        DeleteConfirm ->
            case Maybe.map .id model.existing of
                Just id ->
                    ( model
                    , FormDelete id
                    )

                Nothing ->
                    ( model, FormNone )

        DeleteCancel ->
            ( { model | deleteRequested = False }
            , FormNone
            )

        RequestDelete ->
            ( { model | deleteRequested = True }, FormNone )

        Cancel ->
            ( model, FormCancelled )

        Submit ->
            if formInvalid model then
                ( model, FormNone )

            else
                let
                    ac =
                        { id =
                            if isCreate model then
                                Nothing

                            else
                                model.idField
                        , name = model.nameField
                        , validity = Data.ValidityValue.toMillis model.validityField
                        , enabled = model.enabledField
                        }
                in
                case Maybe.map .id model.existing of
                    Just id ->
                        ( model, FormModified id ac )

                    Nothing ->
                        ( model, FormCreated ac )



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
                [ classList
                    [ ( "hidden", isCreate model )
                    ]
                , class "mb-4"
                ]
                [ label
                    [ class S.inputLabel
                    , for "alias-id"
                    ]
                    [ text texts.id
                    ]
                , input
                    [ type_ "text"
                    , id "alias-id"
                    , onInput SetId
                    , Maybe.withDefault "" model.idField
                        |> value
                    , class S.textInput
                    ]
                    []
                , div
                    [ classList
                        [ ( "hidden", isCreate model )
                        ]
                    , class S.warnMessage
                    , class "mt-2"
                    ]
                    [ div [ class S.header3 ]
                        [ text texts.noteToIdsHead
                        ]
                    , Html.map (\_ -> Cancel) texts.noteToIds
                    ]
                ]
            , div
                [ classList
                    [ ( "required field", True )
                    , ( "error", String.isEmpty model.nameField )
                    ]
                , class "mb-4"
                ]
                [ label
                    [ class S.inputLabel
                    , for "alias-name"
                    ]
                    [ text texts.name
                    , B.inputRequired
                    ]
                , input
                    [ type_ "text"
                    , value model.nameField
                    , onInput SetName
                    , class S.textInput
                    , classList
                        [ ( S.inputErrorBorder, String.isEmpty model.nameField )
                        ]
                    , id "alias-name"
                    ]
                    []
                ]
            , div [ class "mb-4" ]
                [ label
                    [ class S.inputLabel
                    ]
                    [ text texts.validity
                    , B.inputRequired
                    ]
                , Html.map ValidityMsg
                    (Comp.ValidityField.view
                        texts.validityField
                        model.validityField
                        model.validityModel
                    )
                ]
            , div [ class "mb-4" ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { id = "alias-enabled"
                        , value = model.enabledField
                        , tagger = \_ -> ToggleEnabled
                        , label = texts.enabled
                        }
                ]
            ]
        , div
            [ class "mb-4"
            ]
            [ button
                [ type_ "button"
                , class S.primaryButton
                , class "mr-2"
                , onClick Submit
                ]
                [ text texts.submit
                ]
            , button
                [ class S.secondaryButton
                , type_ "button"
                , onClick Cancel
                ]
                [ text texts.back
                ]
            , button
                [ class "float-right"
                , class S.deleteButton
                , classList [ ( "hidden", isCreate model ) ]
                , type_ "button"
                , onClick RequestDelete
                ]
                [ text texts.delete
                ]
            ]
        ]
