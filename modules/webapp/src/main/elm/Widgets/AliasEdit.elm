module Widgets.AliasEdit exposing (..)

import Http
import Json.Decode as Decode
import Html exposing (Html, div, form, input, select, option, h2, text, label, a, p)
import Html.Attributes exposing (class, classList, selected, value, placeholder, type_, name, checked)
import Html.Events exposing (onInput, onCheck, onClick)

import Data exposing (Alias, RemoteUrls)
import PageLocation as PL

type alias Model =
    {current: Alias
    ,currentId: String
    ,urls: RemoteUrls
    ,validityUnit: String
    ,validityNum: String
    ,errorMessage: Maybe String
    ,infoMessage: Maybe String
    }

makeModel: Alias -> RemoteUrls -> Model
makeModel alia urls =
    case Data.parseDuration alia.validity of
        Just (n, unit) ->
            Model alia alia.id urls unit (toString n) Nothing Nothing
        Nothing ->
            Model alia alia.id urls "" ""  Nothing Nothing

hasError: Model -> Bool
hasError model = Data.isPresent model.errorMessage

hasInfo: Model -> Bool
hasInfo model = Data.isPresent model.infoMessage

type Msg
    = SetName String
    | SetValidityNum String
    | SetValidityUnit String
    | SetEnabled Bool
    | SetId String
    | TrySubmit
    | SubmitAliasResult (Result Http.Error Alias)

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        SetId id ->
            let
                a = model.current
                na = {a | id = id}
            in
            {model | current = na, errorMessage = Nothing} ! []

        SetName name ->
            let
                a = model.current
                na = {a | name = name}
            in
            {model | current = na, errorMessage = Nothing} ! []

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
            let
                a = model.current
                na = {a | enable = flag}
            in
            {model | current = na, errorMessage = Nothing} ! []

        TrySubmit ->
            case String.toInt model.validityNum of
                Ok n ->
                    let
                        validity = model.validityNum ++ model.validityUnit
                        thisAlias = model.current
                        newAlias = {thisAlias | validity = validity}
                        model_ = {model | current = newAlias, errorMessage = Nothing}
                    in
                        model_ ! [httpSubmitAlias model_ model.currentId]
                Err msg ->
                    {model | errorMessage = Just ("Error parsing validity number: "++ msg)} ! []

        SubmitAliasResult (Ok na) ->
            {model| currentId = na.id, current = na, infoMessage = Just "Alias has been updated."} ! []

        SubmitAliasResult (Err error) ->
            {model | errorMessage = Just (Data.errorMessage error), infoMessage = Nothing} ! [PL.timeoutCmd error]



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
                 label [][text "Id"]
                ,input [onInput SetId, placeholder "Id", value model.current.id][]
                ,div [class "ui info message"]
                    [div [class "header"][text "Note on changing the id:"]
                    ,p[][text "The id must be globally unique and is used to authorize your public upload site. It therefore changes the URL to the alias page. If it is easy to guess, it may be abused to send spam to you. If unsure, leave the default value."]
                    ]
                ]
            ,div [class "field"]
                [
                 label [][text "Name"]
                ,input [onInput SetName, placeholder "Name", value model.current.name][]
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
                       ,checked model.current.enable
                       ,onCheck SetEnabled
                       ][]
                ,label [][text "Enable"]
                ]
            ,div [class "ui divider"][]
            ,a [class "ui primary button", onClick TrySubmit][text "Submit"]
            ]
        ]

httpSubmitAlias: Model -> String -> Cmd Msg
httpSubmitAlias model id =
    Http.post (model.urls.aliases ++"/"++ id) (Http.jsonBody (Data.encodeAlias model.current))  (Data.decodeAlias)
        |> Http.send SubmitAliasResult
