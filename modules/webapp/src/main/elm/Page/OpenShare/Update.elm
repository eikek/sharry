module Page.OpenShare.Update exposing (update)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.ShareProperties exposing (ShareProperties)
import Comp.Dropzone2
import Comp.MarkdownInput
import Data.Flags exposing (Flags)
import Data.UploadData exposing (UploadData)
import Data.UploadDict
import Data.UploadState exposing (UploadState)
import Http
import Page exposing (Page(..))
import Page.OpenShare.Data exposing (Model, Msg(..))
import Ports
import Util.Http
import Util.Share


update : String -> Flags -> Msg -> Model -> ( Model, Cmd Msg )
update aliasId flags msg model =
    case msg of
        DropzoneMsg lmsg ->
            let
                ( m, c, fs ) =
                    Comp.Dropzone2.update model.uploads.selectedFiles lmsg model.dropzoneModel
            in
            ( { model
                | dropzoneModel = m
                , uploads = Data.UploadDict.updateFiles model.uploads fs
                , formState = BasicResult True ""
              }
            , Cmd.batch [ Cmd.map DropzoneMsg c ]
            )

        DescMsg lmsg ->
            let
                ( m, txt ) =
                    Comp.MarkdownInput.update model.descField lmsg model.descModel
            in
            ( { model
                | descModel = m
                , descField = txt
                , formState = BasicResult True ""
              }
            , Cmd.none
            )

        ClearFiles ->
            ( { model | uploads = Data.UploadDict.updateFiles model.uploads [] }, Cmd.none )

        Submit ->
            let
                valid =
                    Util.Share.validate flags Nothing model
            in
            if valid.success then
                ( { model | uploading = True }
                , Api.createEmptyShareAlias flags aliasId (makeProps model) CreateShareResp
                )

            else
                ( { model | formState = valid }
                , Cmd.none
                )

        CreateShareResp (Ok idres) ->
            let
                ( native, files ) =
                    List.unzip model.uploads.selectedFiles

                uploadUrl =
                    flags.config.baseUrl ++ "/api/v2/alias/upload/" ++ idres.id ++ "/files/tus"

                submit =
                    if native == [] then
                        Cmd.none

                    else
                        UploadData uploadUrl idres.id native (Just aliasId)
                            |> Data.UploadData.encode
                            |> Ports.submitFiles
            in
            if idres.success then
                ( { model | shareId = Just idres.id }, submit )

            else
                ( { model | formState = BasicResult False idres.message }
                , Cmd.none
                )

        CreateShareResp (Err err) ->
            case err of
                Http.BadStatus 403 ->
                    ( model, Page.goto (InfoPage 1) )

                _ ->
                    ( { model
                        | formState = BasicResult False (Util.Http.errorToString err)
                        , uploading = False
                      }
                    , Cmd.none
                    )

        Uploading state ->
            if Just state.id == model.shareId then
                trackUpload flags aliasId model state

            else
                ( model, Cmd.none )

        StartStopUpload ->
            case model.shareId of
                Just id ->
                    ( model
                    , if model.uploadPaused then
                        Ports.startUpload id

                      else
                        Ports.stopUpload id
                    )

                Nothing ->
                    ( model, Cmd.none )

        UploadStopped err ->
            ( { model | uploadPaused = err == Nothing }, Cmd.none )

        ResetForm ->
            ( Page.OpenShare.Data.emptyModel, Cmd.none )

        NotifyResp _ ->
            ( model, Cmd.none )


trackUpload : Flags -> String -> Model -> UploadState -> ( Model, Cmd Msg )
trackUpload flags aliasId model state =
    let
        ( next, progress ) =
            Data.UploadDict.trackUpload model.uploads state

        progressCmd p =
            case p of
                Data.UploadDict.FileProgress index perc ->
                    [ ( "file-progress-" ++ String.fromInt index
                      , perc
                      )
                    ]

                Data.UploadDict.AllProgress perc ->
                    [ ( "all-progress", perc )
                    ]

        infoMsg =
            case state.state of
                Data.UploadState.Failed em ->
                    BasicResult False em

                _ ->
                    model.formState

        notifyCmd =
            if Data.UploadDict.allDone next then
                Api.notifyAliasUpload flags
                    aliasId
                    (Maybe.withDefault "" model.shareId)
                    NotifyResp

            else
                Cmd.none
    in
    ( { model
        | uploads = next
        , uploadPaused = False
        , formState = infoMsg
      }
    , Cmd.batch [ Ports.setProgress (List.concatMap progressCmd progress), notifyCmd ]
    )


makeProps : Model -> ShareProperties
makeProps model =
    { name = Nothing
    , validity = 0
    , description = Just model.descField
    , maxViews = 10
    , password = Nothing
    }
