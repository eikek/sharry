module Pages.Upload.Update exposing (..)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Navigation

import Ports
import Data exposing (Account, UploadId(..), defer)
import PageLocation as PL
import Resumable
import Resumable.Update as ResumableUpdate
import Widgets.UploadForm as UploadForm
import Widgets.UploadProgress as UploadProgress
import Widgets.MarkdownEditor as MarkdownEditor
import Pages.Upload.Model exposing (..)

update: Msg -> Model -> (Model, Cmd Msg, Cmd Msg)
update msg model =
    case msg of
        UploadFormMsg msg ->
            let
                (um, ucmd, ucmdd) = UploadForm.update msg model.uploadFormModel
            in
                {model | uploadFormModel = um} ! [Cmd.map UploadFormMsg ucmd] |> defer (Cmd.map UploadFormMsg ucmdd)

        UploadProgressMsg msg ->
            let
                (um, ucmd) = UploadProgress.update msg model.uploadProgressModel
            in
                {model | uploadProgressModel = um} ! [Cmd.map UploadProgressMsg ucmd] |> defer Cmd.none

        ResetForm ->
            let
                handle = Maybe.withDefault "" model.uploadFormModel.resumableModel.handle
            in
            clearModel model ! [Ports.resumableCancel handle] |> defer Cmd.none

        CancelUpload ->
            let
                handle = Maybe.withDefault "" model.uploadFormModel.resumableModel.handle
            in
            model ! [Ports.resumableCancel handle, httpDeleteUpload model] |> defer Cmd.none

        UploadDeleted (Ok n) ->
            -- its a little hacky: going back means to rebind the resumable handlers
            let
                handle = Maybe.withDefault "" model.uploadFormModel.resumableModel.handle
                cmd = Ports.resumableRebind handle
            in
                clearModel model ! [] |> defer cmd

        UploadDeleted (Err error) ->
            let
                x = Debug.log "Error deleting upload" (Data.errorMessage error)
            in
                clearModel model ! [PL.timeoutCmd error] |> defer Cmd.none

        MoveToUpload ->
            if model.mode == Settings then
                model ! [httpInitUpload model] |> defer Cmd.none
            else
                (model, Cmd.none) |> defer Cmd.none

        UploadCreated (Ok ()) ->
            let
                ufm = model.uploadFormModel
                um = {ufm | errorMessage = Nothing}
                handle = Maybe.withDefault "" model.uploadFormModel.resumableModel.handle
            in
                {model | mode = Upload, uploadFormModel = um} ! [Ports.resumableStart handle] |> defer Cmd.none

        UploadCreated (Err error) ->
            let
                ufm = model.uploadFormModel
                um = {ufm | errorMessage = Just (Data.errorMessage error)}
            in
                {model | uploadFormModel = um} ! [PL.timeoutCmd error] |> defer Cmd.none

        MoveToPublish ->
            model ! [httpPublishUpload model] |> defer Cmd.none

        UploadPublished (Ok info) ->
            let
                model_ = clearModel model
                handle = Maybe.withDefault "" model.uploadFormModel.resumableModel.handle
            in
                model_ ! [PL.downloadPage (Uid info.upload.id), Ports.resetResumable handle] |> defer Cmd.none

        UploadPublished (Err error) ->
            {model | errorMessage = Data.errorMessage error} ! [PL.timeoutCmd error] |> defer Cmd.none

        MarkdownEditorMsg memsg ->
            case model.markdownEditorModel of
                Just mem ->
                    let
                        (mem_, cmd) = MarkdownEditor.update memsg mem
                    in
                        {model | markdownEditorModel = Just mem_} ! [Cmd.map MarkdownEditorMsg cmd] |> defer Cmd.none
                Nothing ->
                    model ! [] |> defer Cmd.none

        ToggleMarkdownEditor ->
            case model.markdownEditorModel of
                Just mem ->
                    let
                        ufm = model.uploadFormModel
                        ufm_ = {ufm | description = mem.text}
                        -- its a little hacky: going back means to rebind the resumable handlers
                        handle = Maybe.withDefault "" model.uploadFormModel.resumableModel.handle
                        cmd = Ports.resumableRebind handle
                    in
                        {model | markdownEditorModel = Nothing, uploadFormModel = ufm_} ! [] |> defer cmd
                Nothing ->
                    let
                        mem = MarkdownEditor.initModel model.uploadFormModel.description
                    in
                        {model | markdownEditorModel = Just mem} ! [] |> defer Cmd.none

        ToggleMarkdownHelp ->
            {model | showMarkdownHelp = not model.showMarkdownHelp} ! [] |> defer Cmd.none


modelEncoder: Model -> Encode.Value
modelEncoder model =
    let
        up = model.uploadFormModel
    in
    Encode.object
    [ ("id", Encode.string (Maybe.withDefault "" up.resumableModel.handle))
    , ("description", Encode.string up.description)
    , ("validity", Encode.string ((toString up.validityNum) ++ up.validityUnit))
    , ("maxdownloads", Encode.int up.maxDownloads)
    , ("password", Encode.string up.password)
    ]


httpInitUpload: Model -> Cmd Msg
httpInitUpload model =
    Http.post model.serverConfig.urls.uploads (Http.jsonBody (modelEncoder model)) (Decode.succeed ())
        |> Http.send UploadCreated

httpDeleteUpload: Model -> Cmd Msg
httpDeleteUpload model =
    case model.uploadFormModel.resumableModel.handle of
        Just h ->
            Data.httpDelete (model.serverConfig.urls.uploads ++ "/" ++ h) Http.emptyBody (Decode.field "filesRemoved" Decode.int)
                |> Http.send UploadDeleted

        Nothing ->
            Cmd.none

httpPublishUpload: Model -> Cmd Msg
httpPublishUpload model =
    case model.uploadFormModel.resumableModel.handle of
        Just h ->
            Http.post (model.serverConfig.urls.uploadPublish ++ "/" ++ h) Http.emptyBody Data.decodeUploadInfo
                |> Http.send UploadPublished
        Nothing ->
            Cmd.none
