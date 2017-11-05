module Widgets.AliasList exposing (..)

import Http
import Html exposing (Html, div, table, th, tr, thead, td, tbody, a, i, text, button, h2)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Json.Decode as Decode

import Ports
import Data exposing (Alias, RemoteConfig, RemoteUrls, defer)
import Widgets.AliasEdit as AliasEdit
import Widgets.MailForm as MailForm
import PageLocation as PL

type Selected
    = EditDetail AliasEdit.Model
    | MailDetail MailForm.Model
    | Table

type alias Model =
    {aliases: List Alias
    ,cfg: RemoteConfig
    ,selected: Selected
    }

makeModel: RemoteConfig -> List Alias -> Model
makeModel cfg aliases =
    Model aliases cfg Table

emptyModel: RemoteConfig -> Model
emptyModel cfg =
    Model [] cfg Table

type Msg
    = DeleteAlias String
    | DeleteAliasResult (Result Http.Error ())
    | AliasListResult (Result Http.Error (List Alias))
    | AddNewAlias
    | EditAlias Alias
    | NewAliasResult (Result Http.Error Alias)
    | AliasEditMsg AliasEdit.Msg
    | BackToTable
    | OpenMailForm Alias
    | MailFormMsg MailForm.Msg


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
                model ! [PL.timeoutCmd error]

        AliasListResult (Ok list) ->
            {model | aliases = list} ! []

        AliasListResult (Err error) ->
            let
                x = Debug.log "Error getting upload list" (Data.errorMessage error)
            in
                model ! [PL.timeoutCmd error]

        AddNewAlias ->
            model ! [httpAddAlias model]

        NewAliasResult (Ok alia) ->
            model ! [httpGetAliases model]

        NewAliasResult (Err error) ->
            model ! [PL.timeoutCmd error]

        AliasEditMsg msg ->
            case model.selected of
                EditDetail am ->
                    let
                        (m, c) = AliasEdit.update msg am
                    in
                        {model | selected = EditDetail m} ! [Cmd.map AliasEditMsg c]
                _ ->
                    model ! []

        EditAlias alia ->
            {model | selected = EditDetail (AliasEdit.makeModel alia model.cfg.urls)} ! []

        BackToTable ->
            case model.selected of
                EditDetail m ->
                    {model | selected = Table} ! [httpGetAliases model]
                _ ->
                    {model | selected = Table} ! []

        OpenMailForm alia ->
            {model | selected = MailDetail (MailForm.makeModel model.cfg.urls)} ! [httpGetTemplate model alia]

        MailFormMsg msg ->
            case model.selected of
                MailDetail m ->
                    let
                        (m_, c) = MailForm.update msg m
                    in
                        {model | selected = MailDetail m_} ! [Cmd.map MailFormMsg c]
                _ ->
                    model ! []

view: Model -> Html Msg
view model =
    case model.selected of
        EditDetail alia ->
            div []
                [
                 button [class "ui button", onClick BackToTable][text "Back"]
                ,div [class "ui divider"][]
                ,createAliasEdit alia
                ]
        MailDetail mf ->
            div [class "sixteen wide column"]
                [
                 a [class "ui button", onClick BackToTable][text "Back"]
                ,div [class "ui divider"][]
                ,div [class "sixteen wide column"]
                    [h2 [class "ui header"][text "Send an email"]
                    ,(Html.map MailFormMsg (MailForm.view mf))
                    ]
                ]

        Table ->
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
                        (List.map (createRow model) model.aliases)
                    ]
                ]

createAliasEdit: AliasEdit.Model -> Html Msg
createAliasEdit aliasModel =
    Html.map AliasEditMsg (AliasEdit.view aliasModel)

createRow: Model -> Alias -> Html Msg
createRow model alia =
    let
        no = "brown minus square outline icon"
        yes = "brown checkmark box icon"
    in
    tr[]
        [
         td []
             [a [href (PL.aliasUploadPageHref alia.id)][text alia.name]]
        ,td [class "center aligned"][alia.created |> Data.formatDate |> text]
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
            ,if model.cfg.mailEnabled then
                 a[class "mini ui basic button", onClick (OpenMailForm alia)]
                     [
                      i [class "mail icon"][]
                     ,text "Email"
                     ]
             else
                 div[][]
            ]
        ]

httpAddAlias: Model -> Cmd Msg
httpAddAlias model =
    Http.post model.cfg.urls.aliases Http.emptyBody (Data.decodeAlias)
        |> Http.send NewAliasResult

httpDeleteAlias: Model -> String -> Cmd Msg
httpDeleteAlias model id =
    Data.httpDelete (model.cfg.urls.aliases ++"/"++ id) Http.emptyBody (Decode.succeed ())
        |> Http.send DeleteAliasResult

httpGetAliases: Model -> Cmd Msg
httpGetAliases model =
    Http.get model.cfg.urls.aliases (Decode.list Data.decodeAlias)
        |> Http.send AliasListResult

httpGetTemplate: Model -> Alias -> Cmd Msg
httpGetTemplate model alia =
    let
        href = PL.aliasUploadPageHref alia.id
        url = model.cfg.urls.baseUrl ++ href
        cmd = Http.get (model.cfg.urls.mailAliasTemplate ++ "?url=" ++ (Http.encodeUri url)) MailForm.decodeTemplate
                  |> Http.send MailForm.TemplateResult
    in
        Cmd.map MailFormMsg cmd
