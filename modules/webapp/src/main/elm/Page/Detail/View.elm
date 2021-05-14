module Page.Detail.View exposing (view)

import Api
import Api.Model.ShareDetail exposing (ShareDetail)
import Comp.Basic as B
import Comp.ConfirmModal
import Comp.Dropzone2
import Comp.IntInput
import Comp.MailSend
import Comp.MarkdownInput
import Comp.MenuBar as MB
import Comp.PasswordInput
import Comp.ShareFileList exposing (ViewMode(..))
import Comp.ValidityField
import Comp.Zoom
import Data.Flags exposing (Flags)
import Data.ValidityOptions
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Markdown
import Messages.DetailPage exposing (Texts)
import Page exposing (Page(..))
import Page.Detail.Data
    exposing
        ( DeleteState(..)
        , EditField(..)
        , Model
        , Msg(..)
        , Property(..)
        , PublishState(..)
        , TopMenuState(..)
        , clipboardData
        , isEdit
        , isPublished
        )
import QRCode
import Styles as S
import Util.Html
import Util.Share
import Util.Size


view : Texts -> Flags -> Model -> Html Msg
view texts flags model =
    let
        ( head, desc ) =
            Util.Share.splitDescription model.share texts.yourShare
    in
    div [ class S.content ]
        [ Comp.Zoom.view (Api.fileSecUrl flags model.share.id) model SetZoom QuitZoom
        , deleteLoader texts model
        , div [ class "flex flex-col mb-2" ]
            [ div [ class "" ]
                ([ Markdown.toHtml [ class "markdown-preview" ] head
                 , topMenu texts model
                 ]
                    ++ shareProps texts model
                    ++ shareLink texts flags model
                    ++ [ dropzone texts flags model
                       , messageDiv model
                       , descriptionView texts model desc
                       , middleMenu texts model
                       , fileList texts flags model
                       ]
                )
            ]
        ]


descriptionView : Texts -> Model -> String -> Html Msg
descriptionView texts model desc =
    case model.descEdit of
        Just ( dm, str ) ->
            div
                [ class "flex flex-col mt-2 px-2 py-1"
                , class S.box
                ]
                [ Html.map DescEditMsg
                    (Comp.MarkdownInput.view texts.markdownInput
                        []
                        str
                        dm
                    )
                , div [ class "flex flex-row py-2" ]
                    [ a
                        [ class S.primaryButton
                        , onClick SaveDescription
                        , class "mr-2"
                        , href "#"
                        ]
                        [ i [ class "fa fa-save mr-2" ] []
                        , text texts.save
                        ]
                    , a
                        [ class S.secondaryButton
                        , onClick ToggleEditDesc
                        , href "#"
                        ]
                        [ i [ class "fa fa-times mr-2" ] []
                        , text texts.cancel
                        ]
                    ]
                ]

        Nothing ->
            Markdown.toHtml [ class "markdown-preview mt-4" ] desc


fileList : Texts -> Flags -> Model -> Html Msg
fileList texts flags model =
    let
        sett =
            Comp.ShareFileList.Settings
                (Api.fileSecUrl flags model.share.id "")
                model.fileView
                True

        sorted =
            List.sortBy .filename model.share.files
    in
    Html.map FileListMsg <|
        Comp.ShareFileList.view texts.shareFileList
            sett
            sorted
            model.fileListModel


shareLink : Texts -> Flags -> Model -> List (Html Msg)
shareLink texts flags model =
    let
        mydiv boxType elements =
            div
                [ class "flex flex-col px-2 py-2 rounded mt-2"
                , class boxType
                , classList
                    [ ( "hidden", model.topMenu /= TopShare )
                    ]
                ]
                elements
    in
    [ case isPublished model.share of
        Unpublished ->
            mydiv S.infoMessage <|
                [ text texts.shareNotPublished
                ]

        PublishOk ->
            mydiv S.box <|
                shareLinkPublished texts flags model

        PublishExpired ->
            mydiv S.warnMessage <|
                [ text texts.shareLinkExpired
                ]

        MaxViewsExceeded ->
            mydiv S.warnMessage <|
                [ text texts.sharePublished
                ]
    ]


shareLinkPublished : Texts -> Flags -> Model -> List (Html Msg)
shareLinkPublished texts flags model =
    let
        share =
            model.share

        pid =
            Maybe.map .id share.publishInfo
                |> Maybe.withDefault ""

        url =
            flags.config.baseUrl ++ Page.pageToString (OpenDetailPage pid)

        qrCodeView : String -> Html msg
        qrCodeView message =
            QRCode.fromString message
                |> Result.map (QRCode.toSvg [])
                |> Result.withDefault
                    (Html.text texts.errorQrCode)
    in
    [ div
        []
        [ text texts.sharePublicAvailableAt
        , pre [ class "text-center" ]
            [ code
                [ id "share-url"
                ]
                [ text url
                ]
            ]
        , text texts.shareAsYouLike
        ]
    , case model.mailForm of
        Just mf ->
            Html.map MailFormMsg
                (Comp.MailSend.view
                    texts.mailSend
                    []
                    mf
                )

        Nothing ->
            div [ class "flex flex-col md:flex-row py-2 h-full items-center justify-center" ]
                [ div [ class "md:w-2/3" ]
                    [ div [ class "flex flex-col items-center  space-y-2 py-2" ]
                        [ a
                            [ class S.primaryButton
                            , Tuple.second clipboardData
                                |> String.dropLeft 1
                                |> id
                            , href "#"
                            , attribute "data-clipboard-target" "#share-url"
                            ]
                            [ i [ class "fa fa-copy mr-2" ] []
                            , text texts.copyLink
                            ]
                        , B.primaryButton
                            { disabled = not flags.config.mailEnabled
                            , icon = "fa fa-envelope"
                            , label = texts.sendEmail
                            , handler = onClick InitMail
                            , attrs =
                                [ href "#"
                                ]
                            }
                        ]
                    ]
                , div
                    [ class "md:w-1/3"
                    ]
                    [ div [ class S.styleQr ]
                        [ qrCodeView url
                        ]
                    ]
                ]
    ]


messageDiv : Model -> Html Msg
messageDiv model =
    Util.Html.resultMsgMaybe model.message


shareProps : Texts -> Model -> List (Html Msg)
shareProps texts model =
    let
        share =
            model.share

        propertyDisplay : String -> String -> List (Html Msg)
        propertyDisplay icon content =
            [ i
                [ class icon
                , class "mr-2"
                ]
                []
            , text content
            ]

        deleteModal =
            Comp.ConfirmModal.defaultSettings
                DeleteConfirm
                DeleteCancel
                texts.yesNo.confirmButton
                texts.yesNo.cancelButton
                texts.yesNo.message
    in
    [ div
        [ classList
            [ ( "hidden", model.topMenu /= TopDetail )
            ]
        , class ("flex flex-col mt-2 rounded pt-2 " ++ S.box)
        ]
        [ Comp.ConfirmModal.view { deleteModal | enabled = model.deleteState == DeleteRequested }
        , div
            [ class "flex flex-col md:flex-row"
            ]
            [ div [ class "flex flex-col w-full md:w-1/2 px-2" ]
                [ property
                    texts
                    { label = texts.name
                    , content =
                        isEdit model Name
                            |> Maybe.map (propertyEdit texts)
                            |> Maybe.withDefault
                                (propertyDisplay "fa fa-comment font-thin"
                                    (Maybe.withDefault "" share.name)
                                )
                    , editAction = Just (ReqEdit Name)
                    }
                , property
                    texts
                    { label = texts.validity
                    , content =
                        isEdit model Validity
                            |> Maybe.map (propertyEdit texts)
                            |> Maybe.withDefault
                                (propertyDisplay "fa fa-hourglass-half"
                                    (Data.ValidityOptions.findValidityItemMillis
                                        texts.validityField
                                        share.validity
                                        |> Tuple.first
                                    )
                                )
                    , editAction = Just (ReqEdit Validity)
                    }
                , property
                    texts
                    { label = texts.maxViews
                    , content =
                        isEdit model MaxViews
                            |> Maybe.map (propertyEdit texts)
                            |> Maybe.withDefault
                                (propertyDisplay "fa fa-eye" (String.fromInt share.maxViews))
                    , editAction = Just (ReqEdit MaxViews)
                    }
                , property
                    texts
                    { label = texts.password
                    , content =
                        isEdit model Password
                            |> Maybe.map (propertyEdit texts)
                            |> Maybe.withDefault
                                (propertyDisplay
                                    (if share.password then
                                        "fa fa-lock"

                                     else
                                        "fa fa-unlock"
                                    )
                                    (if share.password then
                                        texts.passwordProtected

                                     else
                                        texts.passwordNone
                                    )
                                )
                    , editAction = Just (ReqEdit Password)
                    }
                , property
                    texts
                    { label = texts.shareSize
                    , content =
                        propertyDisplay "fa fa-file"
                            (String.fromInt (List.length model.share.files)
                                ++ "/"
                                ++ (List.map .size model.share.files
                                        |> List.sum
                                        |> toFloat
                                        |> Util.Size.bytesReadable Util.Size.B
                                   )
                            )
                    , editAction = Nothing
                    }
                , property
                    texts
                    { label = texts.created
                    , content =
                        propertyDisplay "fa fa-calendar"
                            (texts.dateTime share.created)
                    , editAction = Nothing
                    }
                ]
            , div [ class "flex flex-col w-full md:w-1/2 px-2" ]
                [ property
                    texts
                    { label = texts.aliasLabel
                    , content =
                        propertyDisplay "fa fa-dot-circle font-thin" (Maybe.withDefault "-" share.aliasName)
                    , editAction = Nothing
                    }
                , property
                    texts
                    { label = texts.publishedOn
                    , content =
                        propertyDisplay (Tuple.first <| publishIconLabel texts share)
                            (Maybe.map .publishDate share.publishInfo
                                |> Maybe.map texts.dateTime
                                |> Maybe.withDefault "-"
                            )
                    , editAction = Nothing
                    }
                , property
                    texts
                    { label = texts.publishedUntil
                    , content =
                        propertyDisplay "fa fa-hourglass"
                            (Maybe.map .publishUntil share.publishInfo
                                |> Maybe.map texts.dateTime
                                |> Maybe.withDefault "-"
                            )
                    , editAction = Nothing
                    }
                , property
                    texts
                    { label = texts.lastAccess
                    , content =
                        propertyDisplay "fa fa-calendar font-thin"
                            (Maybe.andThen .lastAccess share.publishInfo
                                |> Maybe.map texts.dateTime
                                |> Maybe.withDefault "-"
                            )
                    , editAction = Nothing
                    }
                , property
                    texts
                    { label = texts.views
                    , content =
                        propertyDisplay "fa fa-eye"
                            (Maybe.map .views share.publishInfo
                                |> Maybe.map String.fromInt
                                |> Maybe.withDefault "-"
                            )
                    , editAction = Nothing
                    }
                ]
            ]
        , div [ class "h-px w-full", class S.border ] []
        , div
            [ classList
                [ ( "hidden", model.topMenu /= TopDetail )
                ]
            , class "flex flex-row px-2 py-2"
            ]
            [ a
                [ classList
                    [ ( "hidden", isPublished share /= Unpublished )
                    ]
                , class "mr-2"
                , class S.secondaryButton
                , onClick (PublishShare False)
                , href "#"
                ]
                [ text texts.publishWithNewLink
                ]
            , a
                [ class S.deleteButton
                , onClick RequestDelete
                , href "#"
                ]
                [ i [ class "fa fa-trash mr-2" ] []
                , text texts.delete
                ]
            ]
        ]
    ]


property :
    Texts
    ->
        { label : String
        , content : List (Html Msg)
        , editAction : Maybe Msg
        }
    -> Html Msg
property texts rec =
    div [ class "mb-3" ]
        [ div [ class "font-semibold text-base" ] <|
            rec.content
        , div [ class "text-sm " ]
            [ case rec.editAction of
                Just msg ->
                    a
                        [ class S.link
                        , href "#"
                        , title texts.edit
                        , onClick msg
                        ]
                        [ i [ class "fa fa-edit mr-2" ] []
                        ]

                Nothing ->
                    text ""
            , span [ class "opacity-75" ]
                [ text rec.label
                ]
            ]
        ]


propertyEdit : Texts -> EditField -> List (Html Msg)
propertyEdit texts ef =
    let
        saveButton =
            button
                [ class S.primaryButtonPlain
                , class "ml-2 rounded-l"
                , href "#"
                , onClick SaveEdit
                , type_ "submit"
                ]
                [ i [ class "fa fa-check" ] []
                ]

        cancelButton =
            a
                [ class S.secondaryButtonPlain
                , class S.secondaryButtonHover
                , class "rounded-r"
                , href "#"
                , onClick CancelEdit
                ]
                [ i [ class "fa fa-times" ] []
                ]
    in
    case ef of
        EditName v ->
            [ div
                [ class "flex flex-row"
                , onSubmit SaveEdit
                ]
                [ div [ class "flex-grow" ]
                    [ input
                        [ type_ "text"
                        , placeholder texts.name
                        , onInput SetName
                        , Maybe.withDefault "" v |> value
                        , class S.textInput
                        , Util.Html.onKeyUpCode EditKey
                        ]
                        []
                    ]
                , saveButton
                , cancelButton
                ]
            ]

        EditMaxViews ( im, n ) ->
            [ div
                [ classList
                    [ ( "error", n == Nothing )
                    ]
                , class "flex flex-row"
                ]
                [ div [ class "flex-grow" ]
                    [ Html.map MaxViewMsg (Comp.IntInput.view n im)
                    ]
                , saveButton
                , cancelButton
                ]
            ]

        EditValidity ( vm, v ) ->
            [ div [ class "flex flex-row" ]
                [ div [ class "flex-grow text-base font-normal" ]
                    [ Html.map ValidityEditMsg
                        (Comp.ValidityField.view texts.validityField v vm)
                    ]
                , saveButton
                , cancelButton
                ]
            ]

        EditPassword ( pm, p ) ->
            [ div [ class "flex flex-row" ]
                [ div [ class "flex-grow mr-2" ]
                    [ Html.map PasswordEditMsg
                        (Comp.PasswordInput.view
                            { placeholder = "" }
                            p
                            False
                            pm
                        )
                    ]
                , saveButton
                , cancelButton
                ]
            ]


topMenu : Texts -> Model -> Html Msg
topMenu texts model =
    let
        share =
            model.share

        ( publishIcon, label ) =
            publishIconLabel texts share
    in
    MB.view
        { start =
            [ MB.ToggleButton
                { tagger = SetTopMenu TopDetail
                , label = texts.detailsMenu
                , icon = Just "fa fa-eye"
                , title = texts.detailsMenu
                , active = model.topMenu == TopDetail
                }
            , MB.ToggleButton
                { tagger = SetTopMenu TopShare
                , label = texts.shareLinkMenu
                , icon = Just "fa fa-share-alt"
                , title = texts.shareLinkMenu
                , active = model.topMenu == TopShare
                }
            , MB.ToggleButton
                { tagger = SetTopMenu TopAddFiles
                , active = model.topMenu == TopAddFiles
                , label = texts.addFilesLinkMenu
                , icon = Just "fa fa-folder-plus"
                , title = texts.addFilesLinkMenu
                }
            ]
        , end =
            [ MB.ToggleButton
                { tagger = ToggleEditDesc
                , label = ""
                , icon = Just "fa fa-edit"
                , title = texts.editDescription
                , active = model.descEdit /= Nothing
                }
            , MB.BasicButton
                { tagger = PublishShare True
                , label = label
                , icon = Just publishIcon
                , title = ""
                }
            ]
        , rootClasses = "mt-3"
        }


publishIconLabel : Texts -> ShareDetail -> ( String, String )
publishIconLabel texts share =
    case isPublished share of
        Unpublished ->
            ( S.unpublished, texts.publish )

        PublishExpired ->
            ( S.publishError, texts.unpublish )

        MaxViewsExceeded ->
            ( S.publishError, texts.unpublish )

        PublishOk ->
            ( S.published, texts.unpublish )


middleMenu : Texts -> Model -> Html Msg
middleMenu texts model =
    MB.view
        { start =
            []
        , end =
            [ MB.ToggleButton
                { tagger = SetFileView ViewList
                , active = model.fileView == ViewList
                , label = ""
                , icon = Just "fa fa-list"
                , title = texts.listView
                }
            , MB.ToggleButton
                { tagger = SetFileView ViewCard
                , active = model.fileView == ViewCard
                , label = ""
                , icon = Just "fa fa-th"
                , title = texts.cardView
                }
            ]
        , rootClasses = "my-2"
        }


dropzone : Texts -> Flags -> Model -> Html Msg
dropzone texts flags model =
    let
        viewSettings =
            Comp.Dropzone2.mkViewSettings (not model.uploading) model.uploads
    in
    div
        [ classList
            [ ( "hidden", model.topMenu /= TopAddFiles )
            ]
        , class S.box
        , class "flex flex-col mt-2 rounded px-2 py-2"
        ]
        [ div [ class "flex flex-row space-x-2" ]
            [ B.primaryButton
                { handler = onClick SubmitFiles
                , label = texts.submit
                , icon = "fa fa-upload"
                , disabled = False
                , attrs = [ href "#" ]
                }
            , B.secondaryButton
                { handler = onClick ResetFileForm
                , label = texts.clear
                , icon = "fa fa-undo"
                , disabled = False
                , attrs = [ href "#" ]
                }
            , div [ class "flex flex-row flex-grow justify-end" ]
                [ B.secondaryButton
                    { handler = onClick StartStopUpload
                    , label =
                        if model.uploadPaused then
                            texts.resume

                        else
                            texts.pause
                    , icon =
                        if model.uploadPaused then
                            "fa fa-play"

                        else
                            "fa fa-pause"
                    , disabled = not model.uploading
                    , attrs = [ href "#" ]
                    }
                ]
            ]
        , p [ class "py-3" ]
            [ toFloat flags.config.maxSize
                |> Util.Size.bytesReadable Util.Size.B
                |> texts.uploadsGreaterThan
                |> text
            ]
        , div
            [ classList
                [ ( S.errorMessage, True )
                , ( "hidden", model.uploadFormState.success )
                ]
            , class "mb-2"
            ]
            [ text model.uploadFormState.message
            ]
        , Html.map DropzoneMsg
            (Comp.Dropzone2.view
                texts.dropzone
                viewSettings
                model.dropzone
            )
        ]


deleteLoader : Texts -> Model -> Html Msg
deleteLoader texts model =
    B.loadingDimmer
        { label = texts.waitDeleteShare
        , active = model.deleteState == DeleteInProgress
        }
