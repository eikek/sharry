module App.Data exposing (..)

import Api.Model.AuthResult exposing (AuthResult)
import Api.Model.VersionInfo exposing (VersionInfo)
import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Data.Flags exposing (Flags)
import Data.UiTheme exposing (UiTheme)
import Data.UploadState exposing (UploadState)
import Http
import Language exposing (Language)
import Page exposing (Page(..))
import Page.Account.Data
import Page.Alias.Data
import Page.Detail.Data
import Page.Home.Data
import Page.Info.Data
import Page.Login.Data
import Page.NewInvite.Data
import Page.OpenDetail.Data
import Page.OpenShare.Data
import Page.Register.Data
import Page.Settings.Data
import Page.Share.Data
import Page.Upload.Data
import Url exposing (Url)
import Util.Maybe


type alias Model =
    { flags : Flags
    , key : Key
    , page : Page
    , navMenuOpen : Bool
    , langMenuOpen : Bool
    , version : VersionInfo
    , homeModel : Page.Home.Data.Model
    , loginModel : Page.Login.Data.Model
    , registerModel : Page.Register.Data.Model
    , newInviteModel : Page.NewInvite.Data.Model
    , infoModel : Page.Info.Data.Model
    , accountModel : Page.Account.Data.Model
    , uploadModel : Page.Upload.Data.Model
    , aliasModel : Page.Alias.Data.Model
    , shareModel : Page.Share.Data.Model
    , openShareModel : Page.OpenShare.Data.Model
    , settingsModel : Page.Settings.Data.Model
    , detailModel : Page.Detail.Data.Model
    , openDetailModel : Page.OpenDetail.Data.Model
    , anonymousTheme : UiTheme
    }


init : Key -> Url -> Flags -> Model
init key url flags_ =
    let
        flags =
            initBaseUrl url flags_

        page =
            Page.fromUrl url |> Maybe.withDefault HomePage
    in
    { flags = flags
    , key = key
    , page = page
    , navMenuOpen = False
    , langMenuOpen = False
    , version = Api.Model.VersionInfo.empty
    , homeModel = Page.Home.Data.emptyModel
    , loginModel = Page.Login.Data.empty
    , registerModel = Page.Register.Data.emptyModel
    , newInviteModel = Page.NewInvite.Data.emptyModel
    , infoModel = Page.Info.Data.emptyModel
    , accountModel = Page.Account.Data.emptyModel
    , uploadModel = Page.Upload.Data.emptyModel
    , aliasModel = Page.Alias.Data.emptyModel flags
    , shareModel = Page.Share.Data.emptyModel flags
    , openShareModel = Page.OpenShare.Data.emptyModel
    , settingsModel = Page.Settings.Data.emptyModel
    , detailModel = Page.Detail.Data.emptyModel
    , openDetailModel = Page.OpenDetail.Data.emptyModel
    , anonymousTheme = Data.UiTheme.Light
    }


type Msg
    = NavRequest UrlRequest
    | NavChange Url
    | VersionResp (Result Http.Error VersionInfo)
    | HomeMsg Page.Home.Data.Msg
    | LoginMsg Page.Login.Data.Msg
    | RegisterMsg Page.Register.Data.Msg
    | NewInviteMsg Page.NewInvite.Data.Msg
    | InfoMsg Page.Info.Data.Msg
    | UploadMsg Page.Upload.Data.Msg
    | AliasMsg Page.Alias.Data.Msg
    | ShareMsg Page.Share.Data.Msg
    | OpenShareMsg Page.OpenShare.Data.Msg
    | AccountMsg Page.Account.Data.Msg
    | SettingsMsg Page.Settings.Data.Msg
    | DetailMsg Page.Detail.Data.Msg
    | OpenDetailMsg Page.OpenDetail.Data.Msg
    | Logout
    | LogoutResp (Result Http.Error ())
    | SessionCheckResp (Result Http.Error AuthResult)
    | SetPage Page
    | ToggleNavMenu
    | UploadStateMsg (Result String UploadState)
    | UploadStoppedMsg (Maybe String)
    | ReceiveLanguage String
    | SetLanguage Language
    | ToggleLangMenu
    | ToggleDarkMode


initBaseUrl : Url -> Flags -> Flags
initBaseUrl url flags_ =
    let
        cfg =
            flags_.config

        baseUrl =
            if cfg.baseUrl == "" then
                Url.toString
                    { url | path = "", query = Nothing, fragment = Nothing }

            else
                cfg.baseUrl

        cfgNew =
            { cfg | baseUrl = baseUrl }
    in
    { flags_ | config = cfgNew }


isSignedIn : Flags -> Bool
isSignedIn flags =
    flags.account
        |> Maybe.map .success
        |> Maybe.withDefault False


isAdmin : Flags -> Bool
isAdmin flags =
    flags.account
        |> Util.Maybe.filter .success
        |> Maybe.map .admin
        |> Maybe.withDefault False


checkPage : Flags -> Page -> Page
checkPage flags page =
    if Page.isAdmin page && not (isAdmin flags) then
        InfoPage 0

    else if Page.isSecured page && isSignedIn flags then
        page

    else if Page.isOpen page then
        page

    else
        Page.loginPage page


defaultPage : Flags -> Page
defaultPage flags =
    if isSignedIn flags then
        HomePage

    else
        LoginPage ( Nothing, False )
