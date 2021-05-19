module Page.Share.Update exposing (update)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Comp.Dropzone2
import Comp.IntField
import Comp.MarkdownInput
import Comp.PasswordInput
import Comp.ValidityField
import Data.Flags exposing (Flags)
import Data.UploadData exposing (UploadData)
import Data.UploadDict
import Data.UploadState exposing (UploadState)
import Page.Share.Data exposing (Model, Msg(..), makeProps)
import Ports
import Util.Http
import Util.Maybe
import Util.Share


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
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

        ValidityMsg lmsg ->
            let
                ( m, sel ) =
                    Comp.ValidityField.update lmsg model.validityModel
            in
            ( { model
                | validityModel = m
                , validityField = Maybe.withDefault model.validityField sel
              }
            , Cmd.none
            )

        PasswordMsg lmsg ->
            let
                ( m, pw ) =
                    Comp.PasswordInput.update lmsg model.passwordModel
            in
            ( { model | passwordModel = m, passwordField = pw }
            , Cmd.none
            )

        MaxViewMsg lmsg ->
            let
                ( m, v ) =
                    Comp.IntField.update lmsg model.maxViewModel
            in
            ( { model
                | maxViewModel = m
                , maxViewField = v
              }
            , Cmd.none
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

        SetName str ->
            ( { model | nameField = Util.Maybe.fromString str }
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
                , Api.createEmptyShare flags (makeProps model) CreateShareResp
                )

            else
                ( { model | formState = valid }
                , Cmd.none
                )

        CreateShareResp (Ok idres) ->
            let
                ( native, _ ) =
                    List.unzip model.uploads.selectedFiles

                uploadUrl =
                    flags.config.baseUrl ++ "/api/v2/sec/upload/" ++ idres.id ++ "/files/tus"

                submit =
                    if native == [] then
                        Cmd.none

                    else
                        UploadData uploadUrl idres.id native Nothing
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
            ( { model
                | formState = BasicResult False (Util.Http.errorToString err)
                , uploading = False
              }
            , Cmd.none
            )

        Uploading state ->
            if Just state.id == model.shareId then
                trackUpload model state

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
            let
                infoMsg =
                    case err of
                        Just m ->
                            BasicResult False m

                        Nothing ->
                            model.formState
            in
            ( { model
                | uploadPaused = err == Nothing
                , formState = infoMsg
              }
            , Cmd.none
            )

        ResetForm ->
            ( Page.Share.Data.emptyModel flags, Cmd.none )


trackUpload : Model -> UploadState -> ( Model, Cmd Msg )
trackUpload model state =
    let
        next =
            Data.UploadDict.trackUpload model.uploads state

        infoMsg =
            case state.state of
                Data.UploadState.Failed em ->
                    BasicResult False em

                _ ->
                    model.formState
    in
    ( { model
        | uploads = next
        , uploadPaused = False
        , formState = infoMsg
      }
    , Cmd.none
    )
