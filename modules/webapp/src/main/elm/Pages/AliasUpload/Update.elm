module Pages.AliasUpload.Update exposing (..)

import Http
import Json.Decode as Decode
import Json.Encode as Encode

import Resumable
import Ports
import Data exposing (defer)
import PageLocation as PL
import Pages.AliasUpload.Model exposing (..)
import Widgets.AliasUploadForm as AliasUploadForm
import Widgets.UploadProgress as UploadProgress
import Widgets.MarkdownEditor as MarkdownEditor

update: Msg -> Model -> (Model, Cmd Msg, Cmd Msg)
update msg model =
    case msg of
        AliasUploadFormMsg msg ->
            let
                (um, ucmd, ucmdd) = AliasUploadForm.update msg model.uploadForm
            in
                {model | uploadForm = um} ! [Cmd.map AliasUploadFormMsg ucmd] |> defer (Cmd.map AliasUploadFormMsg ucmdd)

        UploadProgressMsg msg ->
            let
                (um, ucmd) = UploadProgress.update msg model.uploadProgress
                model_ = {model | uploadProgress = um}
            in
                model_ ! [Cmd.map UploadProgressMsg ucmd, httpNotifyWhenDone model_] |> defer Cmd.none

        InitUpload ->
            model ! [httpInitUpload model] |> defer Cmd.none

        UploadCreated (Ok ()) ->
            let
                ufm = model.uploadForm
                um = {ufm | errorMessage = Nothing}
                handle = Maybe.withDefault "" model.uploadForm.resumableModel.handle
                (cmd1, cmd2) =
                    if AliasUploadForm.hasFiles model.uploadForm then
                        (Ports.resumableStart handle, Cmd.none)
                    else
                        (Cmd.none, Ports.resumableSetComplete (handle, "."++UploadProgress.progressClass))
            in
                {model | mode = Upload, uploadForm = um} ! [cmd1] |> defer cmd2

        UploadCreated (Err error) ->
            let
                ufm = model.uploadForm
                um = {ufm | errorMessage = Just (Data.errorMessage error)}
            in
                {model | uploadForm = um} ! [PL.timeoutCmd error] |> defer Cmd.none

        ResetForm ->
            clearModel model ! [Ports.reloadPage ()] |> defer Cmd.none

        CancelUpload ->
            let
                handle = Maybe.withDefault "" model.uploadForm.resumableModel.handle
            in
                model ! [Ports.resumableCancel handle, httpDeleteUpload model] |> defer Cmd.none

        UploadDeleted (Ok n) ->
            -- its a little hacky: going back means to rebind the resumable handlers
            let
                handle = Maybe.withDefault "" model.uploadForm.resumableModel.handle
                cmd = Ports.resumableRebind handle
            in
                clearModel model ! [] |> defer cmd

        UploadDeleted (Err error) ->
            let
                m = clearModel model
            in
                {m | errorMessage = Data.errorMessage error} ! [PL.timeoutCmd error] |> defer Cmd.none

        NotifyResult res ->
            model ! [] |> defer Cmd.none

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
                        ufm = model.uploadForm
                        ufm_ = {ufm | description = mem.text}
                        -- its a little hacky: going back means to rebind the resumable handlers
                        handle = Maybe.withDefault "" model.uploadForm.resumableModel.handle
                        cmd = Ports.resumableRebind handle
                    in
                        {model | markdownEditorModel = Nothing, uploadForm = ufm_} ! [] |> defer cmd
                Nothing ->
                    let
                        mem = MarkdownEditor.initModel model.uploadForm.description
                    in
                        {model | markdownEditorModel = Just mem} ! [] |> defer Cmd.none

        ToggleMarkdownHelp ->
            {model | showMarkdownHelp = not model.showMarkdownHelp} ! [] |> defer Cmd.none


modelEncoder: Model -> Encode.Value
modelEncoder model =
    let
        up = model.uploadForm
    in
    Encode.object
    [ ("id", Encode.string (Maybe.withDefault "" up.resumableModel.handle))
    , ("description", Encode.string up.description)
    , ("validity", Encode.string "1h") -- dummy values follow
    , ("maxdownloads", Encode.int 30)
    , ("password", Encode.string "")
    ]


httpInitUpload: Model -> Cmd Msg
httpInitUpload model =
    case model.alia of
        Just a ->
            let
                header = Http.header model.cfg.aliasHeaderName a.id
                url = model.cfg.urls.uploads
            in
                httpPost url header (Http.jsonBody (modelEncoder model)) (Decode.succeed ())
                |> Http.send UploadCreated
        Nothing ->
            Cmd.none


httpDeleteUpload: Model -> Cmd Msg
httpDeleteUpload model =
    case (model.uploadForm.resumableModel.handle, model.alia) of
        (Just h, Just a) ->
            let
                header = Http.header model.cfg.aliasHeaderName a.id
                url = model.cfg.urls.uploads ++"/"++ h
            in
                httpDelete url header Http.emptyBody (Decode.field "filesRemoved" Decode.int)
                    |> Http.send UploadDeleted
        _ ->
            Cmd.none

httpNotifyWhenDone: Model -> Cmd Msg
httpNotifyWhenDone model =
    if UploadProgress.isComplete model.uploadProgress then
        let
            header = Http.header model.cfg.aliasHeaderName (model.alia |> Maybe.map .id |> Maybe.withDefault "")
            handle = Maybe.withDefault "" model.uploadForm.resumableModel.handle
            url = model.cfg.urls.uploadNotify ++"/"++ handle
        in
            httpPost url header Http.emptyBody (Decode.succeed ())
                |> Http.send NotifyResult
    else
        Cmd.none


httpPost: String -> Http.Header -> Http.Body -> Decode.Decoder a -> (Http.Request a)
httpPost = httpMethod "POST"

httpDelete: String -> Http.Header -> Http.Body -> Decode.Decoder a -> (Http.Request a)
httpDelete = httpMethod "DELETE"


httpMethod: String -> String -> Http.Header -> Http.Body -> Decode.Decoder a -> (Http.Request a)
httpMethod method url header body dec =
    Http.request
        { method = method
        , headers = [header]
        , url = url
        , body = body
        , expect = Http.expectJson dec
        , timeout = Nothing
        , withCredentials = False
        }
