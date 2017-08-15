module App.Update exposing (..)

import Http

import Resumable
import Data exposing (accountDecoder)
import App.Model exposing (..)
import Ports exposing (..)
import PageLocation as PL

import App.Pages as Pages
import Pages.Login.Update as LoginUpdate
import Pages.AccountEdit.Update as AccountEditUpdate
import Pages.Upload.Model as UploadModel
import Pages.Upload.Update as UploadUpdate
import Pages.Download.Model as DownloadModel
import Pages.Download.Update as DownloadUpdate
import Pages.UploadList.Model as UploadListModel
import Pages.UploadList.Update as UploadListUpdate
import Pages.Profile.Model as ProfileModel
import Pages.Profile.Update as ProfileUpdate
import Pages.AliasList.Model as AliasListModel
import Pages.AliasList.Update as AliasListUpdate
import Pages.AliasUpload.Model as AliasUploadModel
import Pages.AliasUpload.Update as AliasUploadUpdate
import Pages.Manual.Model as ManualModel
import Pages.Error.Model as ErrorModel

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UrlChange loc ->
            let
                (model_, cmd) = Pages.withLocation {model | location = loc}
            in
                case model.user of
                    Just _ ->
                        -- unfortunately, the upload pages still needs some
                        -- more: setup of resumable.js event handlers. This is
                        -- tricky because the command must execute _after_ the
                        -- dom elements are present.
                        --
                        -- putting the below in `findNewSharePage` function
                        -- resulted in an uncaugh-type runtime error from
                        -- within elm, that I couldn't resolve.
                        --
                        -- So now these special cases are handled here. In
                        -- order to route the response back to the correct
                        -- part of the model, we add a page attribute.
                        if model_.page == NewSharePage then
                            let
                                cfg = Resumable.makeStandardConfig model_.serverConfig
                                msgs = List.map UploadMsg (UploadModel.resumableMsg (Resumable.Initialize {cfg | page = "newshare"}))
                                (model__, cmd_) = List.foldl combineResults (model_, Cmd.none) msgs
                            in
                                model__ ! [cmd, cmd_]
                        else
                            (model_, cmd)

                    Nothing ->
                        if isPublicPage model_ then
                            (model_, cmd)
                        else
                            model_ ! [PL.loginPage loc]

        SetPage cmd ->
            model ! [cmd]

        DeferredTick time ->
            {model|deferred = []} ! model.deferred

        LoginMsg msg ->
            let
                (val, cmd, user) = LoginUpdate.update msg model.login
                redirect = PL.loginPageRedirect model.location
            in
                case user of
                    Just n ->
                        {model | login = val, page = IndexPage, user = Just n } ! [setAccount n, redirect]
                    _ ->
                        ({model | login = val}, Cmd.map LoginMsg cmd)

        AccountEditMsg msg ->
            let
                (val, cmd) = AccountEditUpdate.update msg model.accountEdit
            in
                ({model | accountEdit = val}, Cmd.map AccountEditMsg cmd)

        UploadMsg msg ->
            let
                (val, cmd, cmdd) = UploadUpdate.update msg model.upload
            in
                ({model| upload = val, deferred = (Cmd.map UploadMsg cmdd) :: model.deferred}, Cmd.map UploadMsg cmd)

        DownloadMsg msg ->
            let
                (val, cmd) = DownloadUpdate.update msg model.download
            in
                {model | download = val} ! [Cmd.map DownloadMsg cmd]

        Logout ->
            case model.user of
                Just acc ->
                    initModel model.serverConfig Nothing model.location ! [removeAccount acc, PL.indexPage]
                Nothing ->
                    (model, Cmd.none)

        LoginRefresh time ->
            case model.user of
                Just acc ->
                    (model, refreshCookie model)
                Nothing ->
                    (model, Cmd.none)

        LoginRefreshDone acc ->
            (model, Cmd.none)

        RandomString s ->
            update (UploadMsg (UploadModel.randomPasswordMsg s)) model

        ResumableMsg page rmsg ->
            -- we have to decide here which pages receive the resumable events
            let
                (model_, cmd_) =
                    if page == "newshare" then
                        let
                            msgs = List.map UploadMsg (UploadModel.resumableMsg rmsg)
                        in
                            List.foldl combineResults (model, Cmd.none) msgs
                    else if page == "aliasupload" then
                        let
                            msgs = List.map AliasUploadMsg (AliasUploadModel.makeResumableMsg rmsg)
                        in
                            List.foldl combineResults (model, Cmd.none) msgs
                    else
                        model ! []
            in
                model_ ! [cmd_]

        UploadData (Ok data) ->
            let
                dlmodel = DownloadModel.makeModel data model.serverConfig model.user
                defcmd = (Ports.initAccordionAndTabs ()) :: (Ports.initEmbeds ()) :: model.deferred
            in
                {model | download = dlmodel, page = DownloadPage, deferred = defcmd} ! []

        UploadData (Err error) ->
            let
                msg = Debug.log "Error getting published download " (Data.errorMessage error)
            in
                {model| page = ErrorPage, errorModel = ErrorModel.initModel msg} ! [PL.timeoutCmd error]

        LoadUploadsResult (Ok uploads) ->
            {model | uploadList = UploadListModel.makeModel model.serverConfig.urls uploads, page = UploadListPage} ! []

        LoadUploadsResult (Err error) ->
            let
                msg = Debug.log "Error getting list of uploads " (Data.errorMessage error)
            in
                {model| page = ErrorPage, errorModel = ErrorModel.initModel msg} ! [PL.timeoutCmd error]

        LoadAliasesResult (Ok aliases) ->
            {model | aliases = AliasListModel.makeModel model.serverConfig aliases, page = AliasListPage} ! []

        LoadAliasesResult (Err error) ->
            let
                msg = Debug.log "Error getting list of aliases " (Data.errorMessage error)
            in
                {model| page = ErrorPage, errorModel = ErrorModel.initModel msg} ! [PL.timeoutCmd error]

        LoadAliasResult (Ok alia) ->
            let
                cfg = Resumable.makeAliasConfig model.serverConfig alia.id
                msgs = List.map AliasUploadMsg (AliasUploadModel.makeResumableMsg (Resumable.Initialize {cfg | page = "aliasupload"}))
                (model_, cmd_) = List.foldl combineResults (model, Cmd.none) msgs
            in
                {model_ | aliasUpload = AliasUploadModel.makeModel model.serverConfig model.user alia, page = AliasUploadPage} ! [cmd_]

        LoadAliasResult (Err error) ->
            let
                msg = Debug.log "Error getting alias " (Data.errorMessage error)
            in
                --empty/invalid alias is handled at the page
                if Data.isNotFound error then
                    model ! [PL.timeoutCmd error]
                else
                    {model| page = ErrorPage, errorModel = ErrorModel.initModel msg} ! [PL.timeoutCmd error]

        UploadListMsg msg ->
            let
                (ulm, ulc) = UploadListUpdate.update msg model.uploadList
            in
                {model | uploadList = ulm} ! [Cmd.map UploadListMsg ulc]

        ProfileMsg msg ->
            case model.profile of
                Just um ->
                    let
                        (m, c) = ProfileUpdate.update msg um
                    in
                        {model | profile = Just m} ! [Cmd.map ProfileMsg c]
                Nothing ->
                    model ! []

        AliasListMsg msg ->
            let
                (m, c) = AliasListUpdate.update msg model.aliases
            in
                {model | aliases = m} ! [Cmd.map AliasListMsg c]

        AliasUploadMsg msg ->
            let
                (val, cmd, cmdd) = AliasUploadUpdate.update msg model.aliasUpload
            in
                ({model| aliasUpload = val, deferred = (Cmd.map AliasUploadMsg cmdd) :: model.deferred}, Cmd.map AliasUploadMsg cmd)

        ManualPageContent (Ok cnt) ->
            let
                (mm, cmd) = ManualModel.update (ManualModel.Content cnt) model.manualModel
            in
                {model | manualModel = mm} ! [Cmd.map ManualMsg cmd]

        ManualPageContent (Err error) ->
            let
                msg = Debug.log "Error loading manual page " (Data.errorMessage error)
            in
                {model| page = ErrorPage, errorModel = ErrorModel.initModel msg} ! []

        ManualMsg msg ->
            let
                (mm, cmd) = ManualModel.update msg model.manualModel
            in
                {model | manualModel = mm} ! [Cmd.map ManualMsg cmd]


combineResults: Msg -> (Model, Cmd Msg) -> (Model, Cmd Msg)
combineResults msg (model, cmd) =
    let
        (m_, c_) = update msg model
    in
        (m_, Cmd.batch [cmd, c_])

refreshCookie: Model -> Cmd Msg
refreshCookie model =
    Http.post (model.serverConfig.urls.authCookie) Http.emptyBody accountDecoder
        |> Http.send LoginRefreshDone
