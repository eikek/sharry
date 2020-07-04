module Page.Detail.Update exposing (update)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.PublishData exposing (PublishData)
import Comp.Dropzone2
import Comp.IntInput
import Comp.MailSend
import Comp.MarkdownInput
import Comp.PasswordInput
import Comp.ShareFileList
import Comp.ValidityField
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.UploadData exposing (UploadData)
import Data.UploadDict
import Data.UploadState exposing (UploadState)
import Data.ValidityValue
import Page exposing (Page(..))
import Page.Detail.Data
    exposing
        ( EditField(..)
        , Model
        , Msg(..)
        , PublishState(..)
        , TopMenuState(..)
        , clipboardData
        , deleteLoader
        , getLoader
        , isEdit
        , isPublished
        , mkEditField
        , noLoader
        )
import Ports
import Util.Http
import Util.Maybe
import Util.Share


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        Init id ->
            ( { model | loader = getLoader }
            , Cmd.batch
                [ Api.getShare flags id DetailResp
                , Ports.initClipboard clipboardData
                ]
            )

        DetailResp (Ok details) ->
            ( { model
                | share = details
                , message = Nothing
                , descEdit = Nothing
                , loader = noLoader
              }
            , Cmd.none
            )

        DetailResp (Err err) ->
            let
                m =
                    Util.Http.errorToString err
            in
            ( { model
                | message = Just (BasicResult False m)
                , loader = noLoader
              }
            , Cmd.none
            )

        SetTopMenu state ->
            let
                newState =
                    if model.topMenu == state then
                        TopClosed

                    else
                        state
            in
            ( { model
                | topMenu = newState
                , descEdit = Nothing
                , message = Nothing
              }
            , Cmd.none
            )

        PublishShare flag ->
            let
                cmd =
                    case isPublished model.share of
                        Unpublished ->
                            Api.publishShare flags model.share.id (PublishData flag) BasicResp

                        _ ->
                            Api.unpublishShare flags model.share.id BasicResp
            in
            ( model, cmd )

        BasicResp (Ok res) ->
            if res.success then
                update flags (Init model.share.id) model

            else
                ( { model | message = Just res }, Cmd.none )

        BasicResp (Err err) ->
            let
                m =
                    Util.Http.errorToString err
            in
            ( { model | message = Just (BasicResult False m) }
            , Cmd.none
            )

        FileListMsg lmsg ->
            let
                ( m, action ) =
                    Comp.ShareFileList.update lmsg model.fileListModel
            in
            case action of
                Comp.ShareFileList.FileClick sf ->
                    ( { model | fileListModel = m, zoom = Just sf }
                    , Ports.scrollTop ()
                    )

                Comp.ShareFileList.FileDelete sf ->
                    ( { model | fileListModel = m, zoom = Nothing }
                    , Api.deleteFile flags model.share.id sf.id BasicResp
                    )

                Comp.ShareFileList.FileNone ->
                    ( { model | fileListModel = m }, Cmd.none )

        SetFileView mode ->
            ( { model
                | fileView = mode
                , fileListModel = Comp.ShareFileList.reset model.fileListModel
              }
            , Cmd.none
            )

        QuitZoom ->
            case model.zoom of
                Just file ->
                    ( { model | zoom = Nothing }, Ports.scrollToElem file.id )

                Nothing ->
                    ( { model | zoom = Nothing }, Cmd.none )

        SetZoom sf ->
            ( { model | zoom = Just sf }, Cmd.none )

        RequestDelete ->
            ( { model
                | yesNoModel = Comp.YesNoDimmer.activate model.yesNoModel
              }
            , Cmd.none
            )

        YesNoMsg lmsg ->
            let
                ( m, flag ) =
                    Comp.YesNoDimmer.update lmsg model.yesNoModel

                cmd =
                    if flag then
                        Api.deleteShare flags model.share.id DeleteResp

                    else
                        Cmd.none

                loading =
                    if flag then
                        deleteLoader

                    else
                        noLoader
            in
            ( { model | yesNoModel = m, loader = loading }, cmd )

        DeleteResp (Ok res) ->
            if res.success then
                ( { model | loader = noLoader }, Page.goto UploadPage )

            else
                ( { model | message = Just res, loader = noLoader }, Cmd.none )

        DeleteResp (Err err) ->
            let
                m =
                    Util.Http.errorToString err
            in
            ( { model | message = Just (BasicResult False m), loader = noLoader }
            , Cmd.none
            )

        ToggleEditDesc ->
            case model.descEdit of
                Just _ ->
                    ( { model | descEdit = Nothing }, Cmd.none )

                Nothing ->
                    ( { model
                        | descEdit =
                            Just
                                ( Comp.MarkdownInput.init
                                , Maybe.withDefault "" model.share.descriptionRaw
                                )
                        , topMenu = TopClosed
                      }
                    , Cmd.none
                    )

        DescEditMsg lmsg ->
            case model.descEdit of
                Just ( dm, txt ) ->
                    let
                        ( m, str ) =
                            Comp.MarkdownInput.update txt lmsg dm
                    in
                    ( { model | descEdit = Just ( m, str ) }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        SaveDescription ->
            case model.descEdit of
                Just ( dm, str ) ->
                    ( model, Api.setDescription flags model.share.id str BasicResp )

                Nothing ->
                    ( model, Cmd.none )

        ReqEdit prop ->
            let
                next =
                    if isEdit model prop /= Nothing then
                        Nothing

                    else
                        Just ( prop, mkEditField flags model prop )
            in
            ( { model | editField = next }, Cmd.none )

        SetName str ->
            case model.editField of
                Just ( p, EditName _ ) ->
                    ( { model | editField = Just ( p, EditName (Util.Maybe.fromString str) ) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        MaxViewMsg lmsg ->
            case model.editField of
                Just ( p, EditMaxViews ( im, c ) ) ->
                    let
                        ( m, mi ) =
                            Comp.IntInput.update lmsg im
                    in
                    ( { model | editField = Just ( p, EditMaxViews ( m, mi ) ) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        ValidityEditMsg lmsg ->
            case model.editField of
                Just ( p, EditValidity ( m, v ) ) ->
                    let
                        ( nm, nv ) =
                            Comp.ValidityField.update lmsg m

                        dv =
                            Maybe.withDefault v nv
                    in
                    ( { model | editField = Just ( p, EditValidity ( nm, dv ) ) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        PasswordEditMsg lmsg ->
            case model.editField of
                Just ( p, EditPassword ( m, _ ) ) ->
                    let
                        ( nm, nv ) =
                            Comp.PasswordInput.update lmsg m
                    in
                    ( { model | editField = Just ( p, EditPassword ( nm, nv ) ) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        CancelEdit ->
            ( { model | editField = Nothing }, Cmd.none )

        SaveEdit ->
            let
                nm =
                    { model | editField = Nothing }
            in
            case model.editField of
                Just ( p, EditName name ) ->
                    ( nm, Api.setName flags model.share.id name BasicResp )

                Just ( p, EditMaxViews ( _, Just value ) ) ->
                    ( nm, Api.setMaxViews flags model.share.id value BasicResp )

                Just ( p, EditMaxViews ( _, Nothing ) ) ->
                    ( nm, Cmd.none )

                Just ( p, EditValidity ( _, value ) ) ->
                    ( nm
                    , Api.setValidity flags
                        model.share.id
                        (Data.ValidityValue.toMillis value)
                        BasicResp
                    )

                Just ( p, EditPassword ( _, pw ) ) ->
                    ( nm, Api.setPassword flags model.share.id pw BasicResp )

                Nothing ->
                    ( nm, Cmd.none )

        ToggleFilesMenu ->
            ( { model | addFilesOpen = not model.addFilesOpen }
            , Cmd.none
            )

        DropzoneMsg lmsg ->
            let
                ( m, c, fs ) =
                    Comp.Dropzone2.update model.uploads.selectedFiles lmsg model.dropzone
            in
            ( { model
                | dropzone = m
                , uploads = Data.UploadDict.updateFiles model.uploads fs
                , uploadFormState = BasicResult True ""
              }
            , Cmd.batch [ Cmd.map DropzoneMsg c ]
            )

        ResetFileForm ->
            ( { model
                | dropzone = Comp.Dropzone2.init
                , uploads = Data.UploadDict.empty
                , uploading = False
                , uploadFormState = BasicResult True ""
              }
            , Cmd.none
            )

        SubmitFiles ->
            let
                ( native, _ ) =
                    List.unzip model.uploads.selectedFiles

                uploadUrl =
                    flags.config.baseUrl ++ "/api/v2/sec/upload/" ++ model.share.id ++ "/files/tus"

                submit =
                    if native == [] then
                        Cmd.none

                    else
                        UploadData uploadUrl model.share.id native Nothing
                            |> Data.UploadData.encode
                            |> Ports.submitFiles

                valid =
                    Util.Share.validate flags
                        (Just model.share)
                        { descField = "", uploads = model.uploads }
            in
            if native == [] then
                ( model, Cmd.none )

            else if valid.success then
                ( { model | uploading = True, uploadFormState = BasicResult True "" }, submit )

            else
                ( { model | uploadFormState = valid }, Cmd.none )

        Uploading state ->
            if state.id == model.share.id then
                let
                    ( nm, nc ) =
                        trackUpload model state

                    ( _, err ) =
                        Data.UploadDict.countDone nm.uploads

                    rm =
                        { nm
                            | dropzone = Comp.Dropzone2.init
                            , uploads = Data.UploadDict.empty
                            , uploading = False
                        }

                    ( im, ic ) =
                        update flags (Init model.share.id) rm
                in
                if Data.UploadDict.allDone nm.uploads then
                    if err == 0 then
                        ( im, Cmd.batch [ nc, ic ] )

                    else
                        ( rm, nc )

                else
                    ( nm, nc )

            else
                ( model, Cmd.none )

        UploadStopped err ->
            ( { model | uploadPaused = err == Nothing }, Cmd.none )

        StartStopUpload ->
            ( model
            , if model.uploadPaused then
                Ports.startUpload model.share.id

              else
                Ports.stopUpload model.share.id
            )

        MailFormMsg lmsg ->
            case model.mailForm of
                Nothing ->
                    ( model, Cmd.none )

                Just msm ->
                    let
                        ( mm, act ) =
                            Comp.MailSend.update flags lmsg msm
                    in
                    case act of
                        Comp.MailSend.Run c ->
                            ( { model | mailForm = Just mm }, Cmd.map MailFormMsg c )

                        Comp.MailSend.Cancelled ->
                            ( { model | mailForm = Nothing }
                            , Cmd.none
                            )

                        Comp.MailSend.Sent ->
                            ( { model | mailForm = Nothing }
                            , Cmd.none
                            )

        InitMail ->
            let
                getTpl =
                    Api.getShareTemplate flags model.share.id

                ( mm, mc ) =
                    Comp.MailSend.init getTpl
            in
            ( { model | mailForm = Just mm }
            , Cmd.map MailFormMsg mc
            )

        CopyToClipboard str ->
            ( model, Cmd.none )


trackUpload : Model -> UploadState -> ( Model, Cmd Msg )
trackUpload model state =
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
                    model.uploadFormState
    in
    ( { model
        | uploads = next
        , uploadPaused = False
        , uploadFormState = infoMsg
      }
    , Ports.setProgress (List.concatMap progressCmd progress)
    )
