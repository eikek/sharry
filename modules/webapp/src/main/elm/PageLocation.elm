module PageLocation exposing (..)

import Navigation
import Data exposing (UploadId(..))

-- index page

indexPageHref: String
indexPageHref = "#"

indexPage: Cmd msg
indexPage =
    Navigation.newUrl indexPageHref


-- login page

loginPageHref: String
loginPageHref = "#login"

loginPage: Navigation.Location -> Cmd msg
loginPage location  =
    let
        url =
            if (String.length location.hash > 1) then
                (loginPageHref ++ "&redirect=" ++ location.hash)
            else
                loginPageHref
    in
        Navigation.newUrl url

loginPageRedirect: Navigation.Location -> Cmd msg
loginPageRedirect loc =
    let
        prefix = loginPageHref ++ "&redirect=#"
    in
        if String.startsWith prefix loc.hash then
            Navigation.newUrl (String.dropLeft ((String.length prefix) - 1) loc.hash)
        else
            indexPage

-- uploads page

uploadsPageHref: String
uploadsPageHref = "#uploads"

uploadsPage: Cmd msg
uploadsPage =
    Navigation.newUrl uploadsPageHref


-- download page

downloadPageHref: UploadId -> String
downloadPageHref uploadId =
    case uploadId of
        Pid id -> "#id=" ++ id
        Uid id -> "#uid=" ++ id

downloadPage: UploadId -> Cmd msgs
downloadPage id =
    Navigation.newUrl (downloadPageHref id)


downloadPageId: String -> Maybe UploadId
downloadPageId hash =
    if String.startsWith "#id=" hash then
        Pid (String.dropLeft 4 hash) |> Just
    else if String.startsWith "#uid=" hash then
        Uid (String.dropLeft 5 hash) |> Just
    else
        Nothing

-- account edit page

accountEditPageHref: String
accountEditPageHref = "#account-edit"

accountEditPage: Cmd msg
accountEditPage =
    Navigation.newUrl accountEditPageHref


-- new share page

newSharePageHref: String
newSharePageHref = "#new-share"

newSharePage: Cmd msg
newSharePage =
    Navigation.newUrl newSharePageHref


-- update account page

profilePageHref: String
profilePageHref = "#profile"

profilePage: Cmd msg
profilePage =
    Navigation.newUrl profilePageHref


-- manage alias pages

aliasListPageHref: String
aliasListPageHref = "#aliases"

aliasListPage: Cmd msg
aliasListPage =
    Navigation.newUrl aliasListPageHref


-- alias uploadFormModel

aliasUploadPageHref: String -> String
aliasUploadPageHref id =
    "#a=" ++ id

aliasUploadPageId: String -> Maybe String
aliasUploadPageId hash =
    if String.startsWith "#a=" hash then
        String.dropLeft 3 hash |> Just
    else
        Nothing

aliasUploadPage: String -> Cmd msg
aliasUploadPage id =
    Navigation.newUrl (aliasUploadPageHref id)
