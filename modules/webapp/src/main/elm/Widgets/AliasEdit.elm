module Widgets.AliasEdit exposing (..)

import Http
import Json.Decode as Decode
import Html exposing (Html, div, form, input, select, option, h2, text, label, a)
import Html.Attributes exposing (class, classList, selected, value, placeholder, type_, name, checked)
import Html.Events exposing (onInput, onCheck, onClick)

import Data exposing (Alias, RemoteUrls)
import PageLocation as PL

type alias Model =
    {alia: Alias
    ,urls: RemoteUrls
    ,validityUnit: String
    ,validityNum: String
    ,name: String
    ,enabled: Bool
    ,errorMessage: Maybe String
    ,infoMessage: Maybe String
    }

makeModel: Alias -> RemoteUrls -> Model
makeModel alia urls =
    case Data.parseDuration alia.validity of
        Just (n, unit) ->
            Model alia urls unit (toString n) alia.name alia.enable Nothing Nothing
        Nothing ->
            Model alia urls "" "" alia.name alia.enable Nothing Nothing

hasError: Model -> Bool
hasError model = Data.isPresent model.errorMessage

hasInfo: Model -> Bool
hasInfo model = Data.isPresent model.infoMessage

type Msg
    = SetName String
    | SetValidityNum String
    | SetValidityUnit String
    | SetEnabled Bool
    | TrySubmit
    | SubmitAliasResult (Result Http.Error ())

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        SetName name ->
            {model | name = name, errorMessage = Nothing} ! []

        SetValidityUnit unit ->
            {model | validityUnit = unit, errorMessage = Nothing} ! []

        SetValidityNum num ->
            if num /= "" then
                case (String.toInt num) of
                    Ok n ->
                        {model | validityNum = num, errorMessage = Nothing} ! []
                    Err msg ->
                        {model | validityNum = num, errorMessage = Just msg} ! []
            else
                {model | validityNum = num} ! []

        SetEnabled flag ->
            {model | enabled = flag, errorMessage = Nothing} ! []

        TrySubmit ->
            case String.toInt model.validityNum of
                Ok n ->
                    let
                        validity = model.validityNum ++ model.validityUnit
                        thisAlias = model.alia
                        new = {thisAlias | name = model.name, enable = model.enabled, validity = validity}
                        model_ = {model | alia = new, errorMessage = Nothing}
                    in
                        model_ ! [httpSubmitAlias model_]
                Err msg ->
                    {model | errorMessage = Just ("Error parsing validity number: "++ msg)} ! []

        SubmitAliasResult (Ok _) ->
            {model| infoMessage = Just "Alias has been updated."} ! []

        SubmitAliasResult (Err error) ->
            {model | errorMessage = Just (Data.errorMessage error)} ! [PL.timeoutCmd error]



view: Model -> Html Msg
view model =
    form [class "ui form"]
        [h2 [class "header"][text "Change Alias"]
        ,form [classList [("ui form", True)
                         ,("error", hasError model)
                         ,("success", hasInfo model)
                         ]]
            [
             div [class "ui error message"]
                 [model.errorMessage |> Maybe.withDefault "" |> text]
            ,div [class "ui success message"]
                 [model.infoMessage |> Maybe.withDefault "" |> text]
            ,div [class "field"]
                [
                 label [][text "Name"]
                ,input [onInput SetName, placeholder "Name", value model.name][]
                ]
            ,div [class "field"]
                [
                 label [][text "Validity"]
                ,div [class "two fields"]
                     [
                      div [class "field"]
                          [
                           input [class "ui input"
                                 ,onInput SetValidityNum
                                 ,type_ "text"
                                 ,placeholder "Number"
                                 ,value model.validityNum][]
                          ]
                     ,div [class "field"]
                         [
                          select [onInput SetValidityUnit]
                             (List.map
                                  (\n -> case n of
                                             (val, unit) -> option [value val, selected <| model.validityUnit == val][text unit])
                                  [("h", "Hours"), ("d", "Days")])
                         ]
                     ]
                ]
            ,div [class "inline ui checkbox field"]
                [
                 input [type_ "checkbox"
                       ,checked model.enabled
                       ,onCheck SetEnabled
                       ][]
                ,label [][text "Enable"]
                ]
            ,div [class "ui divider"][]
            ,a [class "ui primary button", onClick TrySubmit][text "Submit"]
            ]
        ]

httpSubmitAlias: Model -> Cmd Msg
httpSubmitAlias model =
    Http.post (model.urls.aliases ++"/"++ model.alia.id) (Http.jsonBody (Data.encodeAlias model.alia))  (Decode.succeed ())
        |> Http.send SubmitAliasResult
