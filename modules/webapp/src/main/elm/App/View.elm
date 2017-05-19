module App.View exposing (..)

import Html exposing (Html, Attribute, button, div, text, span, h1, a, i, p)
import Html.Attributes exposing (class, classList, href)
import Html.Events exposing (onClick)
import List
import Color exposing (Color)

import App.Update exposing (..)
import App.Model exposing (..)
import App.Pages exposing (..)

import Data exposing (Account)
import PageLocation as PL
import Pages.Login.View as LoginView
import Pages.AccountEdit.View as AccountEditView
import Pages.Upload.View as UploadView
import Pages.Download.View as DownloadView
import Pages.UploadList.View as UploadListView
import Pages.Profile.View as ProfileView
import Pages.AliasList.View as AliasListView
import Pages.AliasUpload.View as AliasUploadView

view: Model -> Html Msg
view model =
    case model.user of
        Nothing ->
            case model.page of
                DownloadPage ->
                    div [class "ui container"]
                        [Html.map DownloadMsg (DownloadView.view model.download)
                        ,(footer model)
                        ]

                AliasUploadPage ->
                    div [class "ui container"]
                        [(Html.map AliasUploadMsg (AliasUploadView.view model.aliasUpload))
                        ,(footer model)]

                _ ->
                    Html.map LoginMsg (LoginView.view model.login)

        Just acc ->
            case model.page of
                LoginPage ->
                    Html.map LoginMsg (LoginView.view model.login)

                IndexPage ->
                    div [class "ui container"]
                        [
                         (navbar acc model)
                        ,(indexView model)
                        ,(footer model)
                        ]

                NewSharePage ->
                    div [class "ui container"]
                        [
                         (navbar acc model)
                        , Html.map UploadMsg (UploadView.view model.upload)
                        ,(footer model)
                        ]
                AccountEditPage ->
                    div [class "ui container"]
                        [ (navbar acc model)
                        , Html.map AccountEditMsg (AccountEditView.view model.accountEdit)
                        ,(footer model)
                        ]

                DownloadPage ->
                    div [class "ui container"]
                        [ (navbar acc model)
                        , Html.map DownloadMsg (DownloadView.view model.download)
                        ,(footer model)
                        ]

                UploadListPage ->
                    div [class "ui container"]
                        [ (navbar acc model)
                        ,(Html.map UploadListMsg (UploadListView.view model.uploadList))
                        ,(footer model)
                        ]

                ProfilePage ->
                    div [class "ui container"]
                        [(navbar acc model)
                        ,model.profile
                        |> Maybe.map ProfileView.view
                        |> Maybe.map (Html.map ProfileMsg)
                        |> Maybe.withDefault (div[][])
                        ,(footer model)
                        ]

                AliasListPage ->
                    div [class "ui container"]
                        [(navbar acc model)
                        ,(Html.map AliasListMsg (AliasListView.view model.aliases))
                        ,(footer model)
                        ]

                AliasUploadPage ->
                    div [class "ui container"]
                        [(navbar acc model)
                        ,(Html.map AliasUploadMsg (AliasUploadView.view model.aliasUpload))
                        ,(footer model)]


adminHtml: Account -> Html Msg -> Html Msg
adminHtml account html =
    if account.admin then html else span[][]

nonAdminHtml: Account -> Html Msg -> Html Msg
nonAdminHtml account html =
    if not account.admin then html else span[][]


navbar: Account -> Model -> Html Msg
navbar account model =
    div [class "ui fixed compact menu"]
        [
         a [href PL.indexPageHref, class "header item"] [text model.serverConfig.appName]
        ,a [href PL.uploadsPageHref, class "item"] [text "My Uploads"]
        ,a [href PL.aliasListPageHref, class "item"][text "Aliases"]
        ,div [class "right menu"]
            [
             a [href PL.accountEditPageHref, class "item"] [text "Edit Accounts"] |> adminHtml account
            ,a [href PL.profilePageHref, class "item"][text "Profile"] |> nonAdminHtml account
            ,a [onClick (Logout), class "item"][text "Logout"]
            ]
        ]


indexView: Model -> Html Msg
indexView model =
    div [class "main ui grid container"]
        [
         div [class "sixteen wide column"]
             [
              div [class "ui padded brown center aligned segment"]
                  [
                   h1 [class "ui header"][text model.serverConfig.appName]
                  ,p [][text "Allows to easily share files with others! Click below to upload files and share the URL."]
                  ,a [class "ui big basic primary button", onClick (SetPage PL.newSharePage)]
                      [
                       i [class "upload icon"][]
                      ,text "New Share …"
                      ]
                  ]
             ]
        ]

footer: Model -> Html msg
footer model =
    Html.footer [class "ui center aligned sharry-footer container"]
        [
         div []
             [
              text "You are using "
             ,a [href "https://github.com/eikek/sharry"]
                 [
                  i [class "disabled github icon"][]
                 ,text model.serverConfig.projectName
                 ]
             ]
        ]
