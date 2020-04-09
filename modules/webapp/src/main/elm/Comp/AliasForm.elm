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
import Comp.ValidityField
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.ValidityValue exposing (ValidityValue(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Messages.AliasForm as T
import Util.Maybe


type alias Model =
    { existing : Maybe AliasDetail
    , nameField : String
    , idField : Maybe String
    , validityModel : Comp.ValidityField.Model
    , validityField : ValidityValue
    , enabledField : Bool
    , yesNoModel : Comp.YesNoDimmer.Model
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
    , enabledField = False
    , yesNoModel = Comp.YesNoDimmer.emptyModel
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
    | YesNoMsg Comp.YesNoDimmer.Msg


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

        YesNoMsg lmsg ->
            let
                ( m, confirmed ) =
                    Comp.YesNoDimmer.update lmsg model.yesNoModel

                id =
                    Maybe.map .id model.existing
            in
            ( { model | yesNoModel = m }
            , if confirmed then
                Maybe.map FormDelete id
                    |> Maybe.withDefault FormNone

              else
                FormNone
            )

        RequestDelete ->
            let
                m =
                    Comp.YesNoDimmer.activate model.yesNoModel
            in
            ( { model | yesNoModel = m }, FormNone )

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


view : T.AliasForm -> Model -> Html Msg
view texts model =
    div []
        [ Html.map YesNoMsg (Comp.YesNoDimmer.view texts.yesNo model.yesNoModel)
        , Html.form [ class "ui top attached form segment" ]
            [ div
                [ classList
                    [ ( "field", True )
                    , ( "invisible", isCreate model )
                    ]
                ]
                [ label [] [ text texts.id ]
                , input
                    [ type_ "text"
                    , Maybe.withDefault "" model.idField
                        |> value
                    , onInput SetId
                    ]
                    []
                , div
                    [ classList
                        [ ( "ui message", True )
                        , ( "invisible hidden", isCreate model )
                        ]
                    ]
                    [ div [ class "header" ]
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
                ]
                [ label [] [ text texts.name ]
                , input
                    [ type_ "text"
                    , value model.nameField
                    , onInput SetName
                    ]
                    []
                ]
            , div [ class "required field" ]
                [ label [] [ text texts.validity ]
                , Html.map ValidityMsg
                    (Comp.ValidityField.view
                        model.validityField
                        model.validityModel
                    )
                ]
            , div [ class "inline required field" ]
                [ div [ class "ui checkbox" ]
                    [ input
                        [ type_ "checkbox"
                        , onCheck (\_ -> ToggleEnabled)
                        , checked model.enabledField
                        ]
                        []
                    , label [] [ text texts.enabled ]
                    ]
                ]
            ]
        , div [ class "ui secondary bottom attached segment" ]
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
                , type_ "button"
                , onClick RequestDelete
                ]
                [ text texts.delete
                ]
            ]
        ]
