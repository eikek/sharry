module Page.Detail.Data exposing
    ( EditField(..)
    , LoaderModel
    , Model
    , Msg(..)
    , Property(..)
    , PublishState(..)
    , TopMenuState(..)
    , deleteLoader
    , emptyModel
    , getLoader
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
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.UploadDict exposing (UploadDict)
import Data.UploadState exposing (UploadState)
import Data.ValidityValue exposing (ValidityValue)
import Http
import Messages.DetailPage exposing (Texts)


type alias Model =
    { share : ShareDetail
    , topMenu : TopMenuState
    , fileListModel : Comp.ShareFileList.Model
    , message : Maybe BasicResult
    , fileView : Comp.ShareFileList.ViewMode
    , zoom : Maybe ShareFile
    , yesNoModel : Comp.YesNoDimmer.Model
    , descEdit : Maybe ( Comp.MarkdownInput.Model, String )
    , editField : Maybe ( Property, EditField )
    , dropzone : Comp.Dropzone2.Model
    , uploads : UploadDict
    , addFilesOpen : Bool
    , uploading : Bool
    , uploadPaused : Bool
    , uploadFormState : BasicResult
    , loader : LoaderModel
    , mailForm : Maybe Comp.MailSend.Model
    }


type TopMenuState
    = TopClosed
    | TopDetail
    | TopShare


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
    , message : Texts -> String
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
    , yesNoModel = Comp.YesNoDimmer.emptyModel
    , descEdit = Nothing
    , editField = Nothing
    , dropzone = Comp.Dropzone2.init
    , uploads = Data.UploadDict.empty
    , addFilesOpen = False
    , uploading = False
    , uploadPaused = True
    , uploadFormState = BasicResult True ""
    , loader = noLoader
    , mailForm = Nothing
    }


deleteLoader : LoaderModel
deleteLoader =
    { active = True
    , message = \texts -> texts.waitDeleteShare
    }


getLoader : LoaderModel
getLoader =
    { active = True
    , message = \texts -> texts.loadingData
    }


noLoader : LoaderModel
noLoader =
    { active = False
    , message = \_ -> ""
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
    | YesNoMsg Comp.YesNoDimmer.Msg
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
    | ToggleFilesMenu
    | DropzoneMsg Comp.Dropzone2.Msg
    | ResetFileForm
    | SubmitFiles
    | Uploading UploadState
    | UploadStopped (Maybe String)
    | StartStopUpload
    | MailFormMsg Comp.MailSend.Msg
    | InitMail


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
