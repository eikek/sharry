module Widgets.AliasList exposing (..)

import Http
import Html exposing (Html, div, table, th, tr, thead, td, tbody, a, i, text, button)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Json.Decode as Decode

import Ports
import Data exposing (Alias, RemoteUrls, defer)
import Widgets.AliasEdit as AliasEdit
import PageLocation as PL

type alias Model =
    {aliases: List Alias
    ,urls: RemoteUrls
    ,selected: Maybe AliasEdit.Model
    }

makeModel: RemoteUrls -> List Alias -> Model
makeModel urls aliases =
    Model aliases urls Nothing

emptyModel: RemoteUrls -> Model
emptyModel urls =
    Model [] urls Nothing

type Msg
    = DeleteAlias String
    | DeleteAliasResult (Result Http.Error ())
    | AliasListResult (Result Http.Error (List Alias))
    | AddNewAlias
    | EditAlias Alias
    | NewAliasResult (Result Http.Error Alias)
    | AliasEditMsg AliasEdit.Msg
    | BackToTable

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        DeleteAlias id ->
            model ! [httpDeleteAlias model id]

        DeleteAliasResult (Ok _) ->
            model ! [httpGetAliases model]

        DeleteAliasResult (Err error) ->
            let
                x = Debug.log "Error deleting upload" (Data.errorMessage error)
            in
                model ! []

        AliasListResult (Ok list) ->
            {model | aliases = list} ! []

        AliasListResult (Err error) ->
            let
                x = Debug.log "Error getting upload list" (Data.errorMessage error)
            in
                model ! []

        AddNewAlias ->
            model ! [httpAddAlias model]

        NewAliasResult (Ok alia) ->
            model ! [httpGetAliases model]

        NewAliasResult (Err error) ->
            model ! []

        AliasEditMsg msg ->
            case model.selected of
                Just am ->
                    let
                        (m, c) = AliasEdit.update msg am
                    in
                        {model | selected = Just m} ! [Cmd.map AliasEditMsg c]
                Nothing ->
                    model ! []

        EditAlias alia ->
            {model | selected = Just (AliasEdit.makeModel alia model.urls)} ! []

        BackToTable ->
            case model.selected of
                Just m ->
                    {model | selected = Nothing, aliases = List.map (insertAlias (Debug.log "alias new is " m.alia)) model.aliases} ! []
                Nothing ->
                    model ! []

view: Model -> Html Msg
view model =
    case model.selected of
        Just alia ->
            div []
                [
                 button [class "ui button", onClick BackToTable][text "Back"]
                ,div [class "ui divider"][]
                ,createAliasEdit alia
                ]
        Nothing ->
            div[]
                [
                 button [class "ui right floated primary button", onClick AddNewAlias]
                     [
                      i [class "add icon"][]
                     ,text "New Alias"
                     ]
                ,table [class "ui selectable celled table"]
                    [
                     thead []
                         [
                          tr []
                              [
                               th[][text "Link"]
                              ,th[][text "Created"]
                              ,th[][text "Validity"]
                              ,th[][text "Enabled"]
                              ,th[][text ""]
                              ]
                         ]
                    ,tbody[]
                        (List.map createRow model.aliases)
                    ]
                ,div [class "ui small modal sharry-alias-edit-modal"]
                    [
                     div [class "content"]
                         [
                  (model.selected
                     |> Maybe.map createAliasEdit
                     |> Maybe.withDefault (div[][]))
                 ]
            ]
        ]

createAliasEdit: AliasEdit.Model -> Html Msg
createAliasEdit aliasModel =
    Html.map AliasEditMsg (AliasEdit.view aliasModel)

insertAlias: Alias -> Alias -> Alias
insertAlias new old =
    if new.id == old.id then new else old

createRow: Alias -> Html Msg
createRow alia =
    let
        no = "brown minus square outline icon"
        yes = "brown checkmark box icon"
    in
    tr[]
        [
         td []
             [a [href (PL.aliasUploadPageHref alia.id)][text alia.name]]
        ,td [class "center aligned"][text alia.created]
        ,td [class "center aligned"]
            [
             text (Data.formatDuration alia.validity)
            ]
        ,td [class "center aligned"]
            [
             i [class (if alia.enable then yes else no)][]
            ]
        ,td [class "right aligned"]
            [
             a [class "mini ui basic primary button", onClick (EditAlias alia)]
                 [
                  i [class "edit icon"][]
                 ,text "Edit"
                 ]
            ,a [class "mini ui basic negative button", onClick (DeleteAlias alia.id)]
                [
                 i [class "remove icon"][]
                ,text "Delete"
                ]
            ]
        ]

httpAddAlias: Model -> Cmd Msg
httpAddAlias model =
    Http.post model.urls.aliases Http.emptyBody (Data.decodeAlias)
        |> Http.send NewAliasResult

httpDeleteAlias: Model -> String -> Cmd Msg
httpDeleteAlias model id =
    Data.httpDelete (model.urls.aliases ++"/"++ id) Http.emptyBody (Decode.succeed ())
        |> Http.send DeleteAliasResult

httpGetAliases: Model -> Cmd Msg
httpGetAliases model =
    Http.get model.urls.aliases (Decode.list Data.decodeAlias)
        |> Http.send AliasListResult
