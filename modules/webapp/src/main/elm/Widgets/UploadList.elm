module Widgets.UploadList exposing (..)

import Http
import Html exposing (Html, div, table, th, tr, thead, td, tbody, a, i, text, select, option, input)
import Html.Attributes exposing (class, href, colspan, value, type_)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode

import Data exposing (Upload, RemoteUrls, UploadId(..))
import PageLocation as PL

type alias Model =
    {uploads: List Upload
    ,urls: RemoteUrls
    ,filter: String
    }

makeModel: RemoteUrls -> List Upload -> Model
makeModel urls uploads =
    Model uploads urls "all"

emptyModel: RemoteUrls -> Model
emptyModel urls =
    Model [] urls "all"

hasAlias: Upload -> Bool
hasAlias upload =
    Data.isPresent upload.alia

type Msg
    = DeleteUpload String
    | DeleteUploadResult (Result Http.Error Int)
    | UploadData (Result Http.Error (List Upload))
    | SetFilter String

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        DeleteUpload id ->
            model ! [httpDeleteUpload model id]

        DeleteUploadResult (Ok n) ->
            model ! [httpGetUploads model]

        DeleteUploadResult (Err error) ->
            let
                x = Debug.log "Error deleting upload" (Data.errorMessage error)
            in
                model ! []

        UploadData (Ok list) ->
            {model | uploads = list} ! []

        UploadData (Err error) ->
            let
                x = Debug.log "Error getting upload list" (Data.errorMessage error)
            in
                model ! []

        SetFilter f ->
            {model | filter = f} ! []


view: Model -> Html Msg
view model =
    table [class "ui selectable celled table"]
        [
         thead []
             [
              tr []
                  [th [colspan 7]
                       [
                        div [class "ui right aligned container"]
                            [
                             select [class "ui dropdown", onInput SetFilter]
                                 [
                                  option [value "all"][text "All"]
                                 ,option [value "incoming"][text "Incoming"]
                                 ,option [value "outgoing"][text "Outgoing"]
                                 ]
                            ]
                       ]
                  ]
             ,tr []
                  [
                   th[][text "Upload"]
                  ,th[][text "Created"]
                  ,th[][text "Password"]
                  ,th[][text "Published"]
                  ,th[][text "Valid"]
                  ,th[][text "Alias"]
                  ,th[][text ""]
                  ]
             ]
        ,tbody[]
            (model.uploads
                |> List.filter (makeFilter model)
                |> List.map createRow)
        ]

makeFilter: Model -> Upload -> Bool
makeFilter model upload =
    let
        present = hasAlias upload
    in
        case model.filter of
            "incoming" -> present
            "outgoing" -> not present
            _ -> True


createRow: Upload -> Html Msg
createRow upload =
    let
        no = "brown minus square outline icon"
        yes = "brown checkmark box icon"
    in
    tr[]
        [
         td []
             [
              a [href (PL.downloadPageHref (Uid upload.id))][text upload.id]
             ]
        ,td [class "center aligned"][Data.formatDate upload.created |> text]
        ,td [class "center aligned"]
            [
             i [class (if upload.requiresPassword then yes else no)][]
            ]
        ,td [class "center aligned"]
            [
             case upload.publishId of
                 Just _ -> i [class yes][]
                 Nothing -> i [class no][]
            ]
        ,td [class "center aligned"]
            [
             i [class (if Data.isValidUpload upload then yes else no)][]
            ]
        ,td []
            [upload.aliasName |> Maybe.withDefault "" |> text]
        ,td [class "center aligned"]
            [
             a [class "mini ui basic button", onClick (DeleteUpload upload.id)]
                 [
                  i [class "remove icon"][]
                 ,text "Delete"
                 ]
            ]
        ]

httpDeleteUpload: Model -> String -> Cmd Msg
httpDeleteUpload model id =
    Data.httpDelete (model.urls.uploads ++ "/" ++ id) Http.emptyBody (Decode.field "filesRemoved" Decode.int)
        |> Http.send DeleteUploadResult

httpGetUploads: Model -> Cmd Msg
httpGetUploads model =
    Http.get model.urls.uploads (Decode.list Data.decodeUpload)
        |> Http.send UploadData
