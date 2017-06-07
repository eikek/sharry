module App.Model exposing (..)

import Resumable
import Data exposing (Alias, Account, RemoteConfig, UploadInfo, Upload, UploadId(..), accountDecoder)
import Http
import Time exposing (Time)
import Pages.Login.Model as LoginModel
import Pages.AccountEdit.Model as AccountEditModel
import Pages.Upload.Model as UploadModel
import PageLocation as PL

import Widgets.DownloadView as DownloadView
import Pages.Login.Update as LoginUpdate
import Pages.Login.Data as LoginData
import Pages.AccountEdit.Model as AccountEditModel
import Pages.AccountEdit.Update as AccountEditUpdate
import Pages.Upload.Model as UploadModel
import Pages.Download.Model as DownloadModel
import Pages.UploadList.Model as UploadListModel
import Pages.Profile.Model as ProfileModel
import Pages.AliasList.Model as AliasListModel
import Pages.AliasUpload.Model as AliasUploadModel
import Time exposing (Time)
import Navigation

type Msg
    = SetPage (Cmd Msg)
    | DeferredTick Time
    | LoginMsg LoginData.Msg
    | AccountEditMsg AccountEditModel.Msg
    | UploadMsg UploadModel.Msg
    | Logout
    | LoginRefresh Time
    | LoginRefreshDone (Result Http.Error Account)
    | ResumableMsg Resumable.Handle Resumable.Msg
    | RandomString String
    | UrlChange Navigation.Location
    | UploadData (Result Http.Error UploadInfo)
    | LoadUploadsResult (Result Http.Error (List Upload))
    | UploadListMsg UploadListModel.Msg
    | DownloadMsg DownloadModel.Msg
    | ProfileMsg ProfileModel.Msg
    | AliasListMsg AliasListModel.Msg
    | LoadAliasesResult (Result Http.Error (List Alias))
    | AliasUploadMsg AliasUploadModel.Msg
    | LoadAliasResult (Result Http.Error Alias)

type Page
    = LoginPage
    | IndexPage
    | NewSharePage
    | AccountEditPage
    | DownloadPage
    | UploadListPage
    | ProfilePage
    | AliasListPage
    | AliasUploadPage
    | TimeoutPage

type alias Model =
    { page: Page
    , location: Navigation.Location
    , login: LoginModel.Model
    , accountEdit: AccountEditModel.Model
    , upload: UploadModel.Model
    , download: DownloadModel.Model
    , uploadList: UploadListModel.Model
    , profile: Maybe ProfileModel.Model
    , aliases: AliasListModel.Model
    , aliasUpload: AliasUploadModel.Model
    , user: Maybe Account
    , serverConfig: RemoteConfig
    , deferred: List (Cmd Msg)
    }

isPublicPage: Model -> Bool
isPublicPage model =
    case model.page of
        LoginPage -> True
        AliasUploadPage -> True
        DownloadPage ->
            case PL.downloadPageId model.location.hash of
                Just (Uid _) -> False
                _ -> True
        _ -> False

initModel: RemoteConfig -> Maybe Account -> Navigation.Location -> Model
initModel cfg acc location =
    { page = Maybe.withDefault LoginPage (Maybe.map (\x -> IndexPage) acc)
    , location = location
    , login = LoginModel.fromUrls cfg.urls
    , accountEdit = AccountEditModel.emptyModel cfg.urls
    , upload = UploadModel.emptyModel cfg
    , download = DownloadModel.emptyModel
    , uploadList = UploadListModel.emptyModel cfg.urls
    , profile = Maybe.map (ProfileModel.makeModel cfg.urls) acc
    , aliases = AliasListModel.emptyModel cfg
    , aliasUpload = AliasUploadModel.emptyModel cfg acc
    , user = acc
    , serverConfig = cfg
    , deferred = []
    }

clearModel: Model -> Model
clearModel model =
    initModel model.serverConfig model.user model.location

isAuthenticated: Model -> Bool
isAuthenticated model =
    Data.isPresent model.user
