module Page.Detail.View exposing (view)

import Api
import Api.Model.ShareDetail exposing (ShareDetail)
import Comp.Dropzone2
import Comp.IntInput
import Comp.MailSend
import Comp.MarkdownInput
import Comp.PasswordInput
import Comp.ShareFileList exposing (ViewMode(..))
import Comp.ValidityField
import Comp.YesNoDimmer
import Comp.Zoom
import Data.Flags exposing (Flags)
import Data.ValidityOptions
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Markdown
import Messages.DetailPage exposing (Texts)
import Page exposing (Page(..))
import Page.Detail.Data
    exposing
        ( EditField(..)
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
import Util.Html
import Util.Share
import Util.Size


view : Texts -> Flags -> Model -> Html Msg
view texts flags model =
    let
        ( head, desc ) =
            Util.Share.splitDescription model.share texts.yourShare
    in
    div [ class "ui grid container detail-page" ]
        [ Comp.Zoom.view (Api.fileSecUrl flags model.share.id) model SetZoom QuitZoom
        , deleteLoader texts model
        , div [ class "row" ]
            [ div [ class "sixteen wide column" ]
                ([ Markdown.toHtml [] head
                 , topMenu texts model
                 ]
                    ++ shareProps texts model
                    ++ shareLink texts flags model
                    ++ [ messageDiv model
                       , descriptionView texts model desc
                       , middleMenu texts model
                       , dropzone texts flags model
                       , fileList texts flags model
                       ]
                )
            ]
        ]


descriptionView : Texts -> Model -> String -> Html Msg
descriptionView texts model desc =
    case model.descEdit of
        Just ( dm, str ) ->
            div [ class "ui form" ]
                [ Html.map DescEditMsg
                    (Comp.MarkdownInput.view texts.markdownInput str dm)
                , div [ class "ui secondary menu" ]
                    [ a
                        [ class "link item"
                        , onClick SaveDescription
                        , href "#"
                        ]
                        [ i [ class "disk icon" ] []
                        , text texts.save
                        ]
                    ]
                ]

        Nothing ->
            Markdown.toHtml [ class "share-description ui basic segment" ] desc


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
    case isPublished model.share of
        Unpublished ->
            shareLinkNotPublished texts model

        PublishOk ->
            shareLinkPublished texts flags model

        PublishExpired ->
            shareLinkExpired texts model

        MaxViewsExceeded ->
            shareLinkMaxViewsExeeded texts model


shareLinkMaxViewsExeeded : Texts -> Model -> List (Html Msg)
shareLinkMaxViewsExeeded texts model =
    [ div
        [ classList
            [ ( "invisible", model.topMenu /= TopShare )
            , ( "ui attached warning message segment", True )
            ]
        ]
        [ text texts.sharePublished
        ]
    ]


shareLinkNotPublished : Texts -> Model -> List (Html Msg)
shareLinkNotPublished texts model =
    [ div
        [ classList
            [ ( "invisible", model.topMenu /= TopShare )
            , ( "ui attached info message segment", True )
            ]
        ]
        [ text texts.shareNotPublished
        ]
    ]


shareLinkExpired : Texts -> Model -> List (Html Msg)
shareLinkExpired texts model =
    [ div
        [ classList
            [ ( "invisible", model.topMenu /= TopShare )
            , ( "ui attached warning message segment", True )
            ]
        ]
        [ text texts.shareLinkExpired
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
            QRCode.encode message
                |> Result.map QRCode.toSvg
                |> Result.withDefault
                    (Html.text texts.errorQrCode)
    in
    [ div
        [ classList
            [ ( "invisible", model.topMenu /= TopShare )
            , ( "ui attached segment", True )
            ]
        ]
        [ text texts.sharePublicAvailableAt
        , pre [ class "url" ]
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
                    [ ( "invisible", model.topMenu /= TopShare )
                    , ( "ui bottom attached segment", True )
                    ]
                    mf
                )

        Nothing ->
            div
                [ classList
                    [ ( "invisible", model.topMenu /= TopShare )
                    , ( "ui bottom attached segment", True )
                    ]
                ]
                [ div [ class "ui two column stackable center aligned grid" ]
                    [ div [ class "ui vertical divider" ]
                        [ text texts.or
                        ]
                    , div
                        [ class "middle aligned row"
                        ]
                        [ div [ class "column" ]
                            [ qrCodeView url
                            ]
                        , div [ class "column" ]
                            [ div [ class "ui vertical buttons" ]
                                [ a
                                    [ class "ui primary labeled icon button"
                                    , Tuple.second clipboardData
                                        |> String.dropLeft 1
                                        |> id
                                    , href "#"
                                    , attribute "data-clipboard-target" "#share-url"
                                    ]
                                    [ i [ class "copy icon" ] []
                                    , text texts.copyLink
                                    ]
                                , a
                                    [ classList
                                        [ ( "ui primary labeled icon button", True )
                                        , ( "disabled", not flags.config.mailEnabled )
                                        ]
                                    , href "#"
                                    , onClick InitMail
                                    ]
                                    [ i [ class "envelope icon" ] []
                                    , text texts.sendEmail
                                    ]
                                ]
                            ]
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
            [ i [ class icon ] []
            , text content
            ]
    in
    [ div
        [ classList
            [ ( "invisible", model.topMenu /= TopDetail )
            , ( "ui attached segment", True )
            ]
        ]
        [ Html.map YesNoMsg (Comp.YesNoDimmer.view texts.yesNo model.yesNoModel)
        , div [ class "ui stackable two column grid" ]
            [ div [ class "column" ]
                [ div [ class "ui items" ]
                    [ property
                        texts
                        { label = texts.name
                        , content =
                            isEdit model Name
                                |> Maybe.map (propertyEdit texts)
                                |> Maybe.withDefault
                                    (propertyDisplay "comment outline icon"
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
                                    (propertyDisplay "hourglass half icon"
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
                                    (propertyDisplay "eye icon" (String.fromInt share.maxViews))
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
                                            "lock icon"

                                         else
                                            "unlock icon"
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
                            propertyDisplay "file icon"
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
                            propertyDisplay "calendar icon"
                                (texts.dateTime share.created)
                        , editAction = Nothing
                        }
                    ]
                ]
            , div [ class "column" ]
                [ div [ class "ui items" ]
                    [ property
                        texts
                        { label = texts.aliasLabel
                        , content =
                            propertyDisplay "dot circle outline icon" (Maybe.withDefault "-" share.aliasName)
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
                            propertyDisplay "hourglass icon"
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
                            propertyDisplay "calendar outline icon"
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
                            propertyDisplay "eye icon"
                                (Maybe.map .views share.publishInfo
                                    |> Maybe.map String.fromInt
                                    |> Maybe.withDefault "-"
                                )
                        , editAction = Nothing
                        }
                    ]
                ]
            ]
        ]
    , div
        [ classList
            [ ( "invisible", model.topMenu /= TopDetail )
            , ( "ui bottom attached secondary segment", True )
            ]
        ]
        [ div [ class "item" ]
            [ button
                [ type_ "button"
                , classList
                    [ ( "ui secondary button", True )
                    , ( "invisible", isPublished share /= Unpublished )
                    ]
                , onClick (PublishShare False)
                ]
                [ text texts.publishWithNewLink
                ]
            , button
                [ type_ "button"
                , class "ui red button"
                , onClick RequestDelete
                ]
                [ i [ class "trash icon" ] []
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
    div [ class "item" ]
        [ div [ class "content" ]
            [ div [ class "header" ] <|
                rec.content
            , div [ class "meta" ]
                [ case rec.editAction of
                    Just msg ->
                        a
                            [ class "ui link"
                            , href "#"
                            , title texts.edit
                            , onClick msg
                            ]
                            [ i [ class "edit icon" ] []
                            , text " "
                            ]

                    Nothing ->
                        text ""
                , text rec.label
                ]
            ]
        ]


propertyEdit : Texts -> EditField -> List (Html Msg)
propertyEdit texts ef =
    let
        saveButton =
            a
                [ class "ui primary icon button"
                , href "#"
                , onClick SaveEdit
                ]
                [ i [ class "check icon" ] []
                ]

        cancelButton =
            a
                [ class "ui secondary icon button"
                , href "#"
                , onClick CancelEdit
                ]
                [ i [ class "delete icon" ] []
                ]
    in
    case ef of
        EditName v ->
            [ div [ class "ui mini action input" ]
                [ input
                    [ type_ "text"
                    , placeholder texts.name
                    , onInput SetName
                    , Maybe.withDefault "" v |> value
                    ]
                    []
                , saveButton
                , cancelButton
                ]
            ]

        EditMaxViews ( im, n ) ->
            [ div
                [ classList
                    [ ( "ui mini action input", True )
                    , ( "error", n == Nothing )
                    ]
                ]
                [ Html.map MaxViewMsg (Comp.IntInput.view n im)
                , saveButton
                , cancelButton
                ]
            ]

        EditValidity ( vm, v ) ->
            [ div [ class "ui mini action input" ]
                [ Html.map ValidityEditMsg (Comp.ValidityField.view texts.validityField v vm)
                , saveButton
                , cancelButton
                ]
            ]

        EditPassword ( pm, p ) ->
            [ div [ class "ui mini action input" ]
                [ Html.map PasswordEditMsg (Comp.PasswordInput.view p pm)
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
    div
        [ classList
            [ ( "ui pointing menu", True )
            , ( "top attached", model.topMenu /= TopClosed )
            ]
        ]
        [ topMenuLink model TopDetail texts.detailsMenu
        , topMenuLink model TopShare texts.shareLinkMenu
        , div [ class "right menu" ]
            [ a
                [ classList
                    [ ( "icon link item", True )
                    , ( "active", model.descEdit /= Nothing )
                    ]
                , href "#"
                , title texts.editDescription
                , onClick ToggleEditDesc
                ]
                [ i [ class "ui edit icon" ] []
                ]
            , a
                [ class "link item"
                , href "#"
                , onClick (PublishShare True)
                ]
                [ i [ class publishIcon ] []
                , text label
                ]
            ]
        ]


publishIconLabel : Texts -> ShareDetail -> ( String, String )
publishIconLabel texts share =
    case isPublished share of
        Unpublished ->
            ( "circle outline icon", texts.publish )

        PublishExpired ->
            ( "red bolt icon", texts.unpublish )

        MaxViewsExceeded ->
            ( "red bolt icon", texts.unpublish )

        PublishOk ->
            ( "green circle icon", texts.unpublish )


topMenuLink : Model -> TopMenuState -> String -> Html Msg
topMenuLink model state label =
    a
        [ classList
            [ ( "active", model.topMenu == state )
            , ( "link item", True )
            ]
        , href "#"
        , onClick (SetTopMenu state)
        ]
        [ text label
        ]


middleMenu : Texts -> Model -> Html Msg
middleMenu texts model =
    div
        [ classList
            [ ( "ui menu", True )
            , ( "attached", model.addFilesOpen )
            ]
        ]
        [ a
            [ classList
                [ ( "icon link item", True )
                , ( "active", model.fileView == ViewList )
                ]
            , href "#"
            , onClick (SetFileView ViewList)
            , title texts.listView
            ]
            [ i [ class "ui list icon" ] []
            ]
        , a
            [ classList
                [ ( "icon link item", True )
                , ( "active", model.fileView == ViewCard )
                ]
            , href "#"
            , onClick (SetFileView ViewCard)
            , title texts.cardView
            ]
            [ i [ class "th icon" ] []
            ]
        , div [ class "right menu" ]
            [ a
                [ classList
                    [ ( "icon link item", True )
                    , ( "active", model.addFilesOpen )
                    ]
                , href "#"
                , onClick ToggleFilesMenu
                ]
                [ i [ class "icons" ]
                    [ i [ class "file outline icon" ] []
                    , i [ class "corner add icon" ] []
                    ]
                ]
            ]
        ]


dropzone : Texts -> Flags -> Model -> Html Msg
dropzone texts flags model =
    let
        viewSettings =
            Comp.Dropzone2.mkViewSettings (not model.uploading) model.uploads
    in
    div
        [ classList
            [ ( "ui bottom attached segment", True )
            , ( "hidden invisible", not model.addFilesOpen )
            ]
        ]
        [ div [ class "ui secondary menu" ]
            [ a
                [ class "primary item"
                , href "#"
                , onClick SubmitFiles
                ]
                [ i [ class "upload icon" ] []
                , text texts.submit
                ]
            , a
                [ class "item"
                , href "#"
                , onClick ResetFileForm
                ]
                [ i [ class "undo icon" ] []
                , text texts.clear
                ]
            , div [ class "right floated menu" ]
                [ a
                    [ classList
                        [ ( "item", True )
                        , ( "disabled", not model.uploading )
                        ]
                    , href "#"
                    , onClick StartStopUpload
                    ]
                    [ i
                        [ class
                            (if model.uploadPaused then
                                "play icon"

                             else
                                "pause icon"
                            )
                        ]
                        []
                    , text
                        (if model.uploadPaused then
                            texts.resume

                         else
                            texts.pause
                        )
                    ]
                ]
            ]
        , p []
            [ toFloat flags.config.maxSize
                |> Util.Size.bytesReadable Util.Size.B
                |> texts.uploadsGreaterThan
                |> text
            ]
        , div
            [ classList
                [ ( "ui error message", True )
                , ( "invisible hidden", model.uploadFormState.success )
                ]
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
    div
        [ classList
            [ ( "ui dimmer", True )
            , ( "active", model.loader.active )
            ]
        ]
        [ div [ class "ui indeterminate text loader" ]
            [ text (model.loader.message texts)
            ]
        ]
