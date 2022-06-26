module Page.Detail.Data exposing
    ( DeleteState(..)
    , EditField(..)
    , LoaderModel
    , Model
    , Msg(..)
    , Property(..)
    , PublishState(..)
    , TopMenuState(..)
    , clipboardData
    , emptyModel
    , isEdit
    , isPublished
    , mkEditField
    , noLoader
    )

import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.ShareDetail exposing (ShareDetail)
import Api.Model.ShareFile exposing (ShareFile)
import Comp.Dropzone2
import Comp.IntInput
import Comp.MailSend
import Comp.MarkdownInput
import Comp.PasswordInput
import Comp.ShareFileList
import Comp.ValidityField
import Data.Flags exposing (Flags)
import Data.InitialView exposing (InitialView)
import Data.UploadDict exposing (UploadDict)
import Data.UploadState exposing (UploadState)
import Data.ValidityValue exposing (ValidityValue)
import Http
import Util.Html exposing (KeyCode)


type alias Model =
    { share : ShareDetail
    , topMenu : TopMenuState
    , fileListModel : Comp.ShareFileList.Model
    , message : Maybe BasicResult
    , fileView : Comp.ShareFileList.ViewMode
    , zoom : Maybe ShareFile
    , deleteState : DeleteState
    , descEdit : Maybe ( Comp.MarkdownInput.Model, String )
    , editField : Maybe ( Property, EditField )
    , dropzone : Comp.Dropzone2.Model
    , uploads : UploadDict
    , uploading : Bool
    , uploadPaused : Bool
    , uploadFormState : BasicResult
    , mailForm : Maybe Comp.MailSend.Model
    , shareUrlMode : InitialView
    }


type DeleteState
    = DeleteNone
    | DeleteRequested
    | DeleteInProgress


type TopMenuState
    = TopClosed
    | TopDetail
    | TopShare
    | TopAddFiles


type PublishState
    = Unpublished
    | PublishOk
    | PublishExpired
    | MaxViewsExceeded


type Property
    = Name
    | MaxViews
    | Validity
    | Password


type alias LoaderModel =
    { active : Bool
    , message : String
    }


type EditField
    = EditName (Maybe String)
    | EditMaxViews ( Comp.IntInput.Model, Maybe Int )
    | EditValidity ( Comp.ValidityField.Model, ValidityValue )
    | EditPassword ( Comp.PasswordInput.Model, Maybe String )


emptyModel : Model
emptyModel =
    { share = Api.Model.ShareDetail.empty
    , topMenu = TopClosed
    , fileListModel = Comp.ShareFileList.init
    , message = Nothing
    , fileView = Comp.ShareFileList.ViewList
    , zoom = Nothing
    , deleteState = DeleteNone
    , descEdit = Nothing
    , editField = Nothing
    , dropzone = Comp.Dropzone2.init
    , uploads = Data.UploadDict.empty
    , uploading = False
    , uploadPaused = True
    , uploadFormState = BasicResult True ""
    , mailForm = Nothing
    , shareUrlMode = Data.InitialView.default
    }


noLoader : LoaderModel
noLoader =
    { active = False
    , message = ""
    }


mkEditField : Flags -> Model -> Property -> EditField
mkEditField flags model prop =
    case prop of
        Name ->
            EditName model.share.name

        MaxViews ->
            EditMaxViews
                ( Comp.IntInput.init (Just 1) Nothing
                , Just model.share.maxViews
                )

        Validity ->
            EditValidity
                ( Comp.ValidityField.init flags
                , Data.ValidityValue.Millis model.share.validity
                )

        Password ->
            EditPassword
                ( Comp.PasswordInput.init
                , Nothing
                )


isEdit : Model -> Property -> Maybe EditField
isEdit model prop =
    Maybe.andThen
        (\t ->
            if Tuple.first t == prop then
                Just (Tuple.second t)

            else
                Nothing
        )
        model.editField


type Msg
    = Init String
    | DetailResp (Result Http.Error ShareDetail)
    | SetTopMenu TopMenuState
    | PublishShare Bool
    | BasicResp (Result Http.Error BasicResult)
    | FileListMsg Comp.ShareFileList.Msg
    | SetFileView Comp.ShareFileList.ViewMode
    | QuitZoom
    | SetZoom ShareFile
    | RequestDelete
    | DeleteConfirm
    | DeleteCancel
    | DeleteResp (Result Http.Error BasicResult)
    | ToggleEditDesc
    | DescEditMsg Comp.MarkdownInput.Msg
    | SaveDescription
    | ReqEdit Property
    | SetName String
    | MaxViewMsg Comp.IntInput.Msg
    | ValidityEditMsg Comp.ValidityField.Msg
    | PasswordEditMsg Comp.PasswordInput.Msg
    | SaveEdit
    | CancelEdit
    | DropzoneMsg Comp.Dropzone2.Msg
    | ResetFileForm
    | SubmitFiles
    | Uploading UploadState
    | UploadStopped (Maybe String)
    | StartStopUpload
    | MailFormMsg Comp.MailSend.Msg
    | InitMail
    | CopyToClipboard String
    | EditKey (Maybe KeyCode)
    | SetShareUrlMode InitialView


isPublished : ShareDetail -> PublishState
isPublished share =
    case share.publishInfo of
        Nothing ->
            Unpublished

        Just info ->
            if not info.enabled then
                Unpublished

            else if info.expired then
                PublishExpired

            else if info.views >= share.maxViews then
                MaxViewsExceeded

            else
                PublishOk


clipboardData : ( String, String )
clipboardData =
    ( "Detail", "#share-copy-to-clipboard-btn" )
