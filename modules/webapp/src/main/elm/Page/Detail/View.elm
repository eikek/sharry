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
import Page exposing (Page(..))
import Page.Detail.Data
    exposing
        ( EditField(..)
        , Model
        , Msg(..)
        , Property(..)
        , PublishState(..)
        , TopMenuState(..)
        , isEdit
        , isPublished
        )
import QRCode
import Util.Html
import Util.Share
import Util.Size
import Util.Time


view : Flags -> Model -> Html Msg
view flags model =
    let
        ( head, desc ) =
            Util.Share.splitDescription model.share
    in
    div [ class "ui grid container detail-page" ]
        [ Comp.Zoom.view (Api.fileSecUrl flags model.share.id) model SetZoom QuitZoom
        , deleteLoader model
        , div [ class "row" ]
            [ div [ class "sixteen wide column" ]
                ([ Markdown.toHtml [] head
                 , topMenu model
                 ]
                    ++ shareProps model
                    ++ shareLink flags model
                    ++ [ messageDiv model
                       , descriptionView model desc
                       , middleMenu model
                       , dropzone flags model
                       , fileList flags model
                       ]
                )
            ]
        ]


descriptionView : Model -> String -> Html Msg
descriptionView model desc =
    case model.descEdit of
        Just ( dm, str ) ->
            div [ class "ui form" ]
                [ Html.map DescEditMsg
                    (Comp.MarkdownInput.view str dm)
                , div [ class "ui secondary menu" ]
                    [ a
                        [ class "link item"
                        , onClick SaveDescription
                        , href "#"
                        ]
                        [ i [ class "disk icon" ] []
                        , text "Save"
                        ]
                    ]
                ]

        Nothing ->
            Markdown.toHtml [ class "share-description ui basic segment" ] desc


fileList : Flags -> Model -> Html Msg
fileList flags model =
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
        Comp.ShareFileList.view sett sorted model.fileListModel


shareLink : Flags -> Model -> List (Html Msg)
shareLink flags model =
    case isPublished model.share of
        Unpublished ->
            shareLinkNotPublished model

        PublishOk ->
            shareLinkPublished flags model

        PublishExpired ->
            shareLinkExpired model

        MaxViewsExceeded ->
            shareLinkMaxViewsExeeded model


shareLinkMaxViewsExeeded : Model -> List (Html Msg)
shareLinkMaxViewsExeeded model =
    [ div
        [ classList
            [ ( "invisible", model.topMenu /= TopShare )
            , ( "ui attached warning message segment", True )
            ]
        ]
        [ text "The share has been published, but its max-views has been reached. You can "
        , text "increase this property if you want to have this published for another while."
        ]
    ]


shareLinkNotPublished : Model -> List (Html Msg)
shareLinkNotPublished model =
    [ div
        [ classList
            [ ( "invisible", model.topMenu /= TopShare )
            , ( "ui attached info message segment", True )
            ]
        ]
        [ text "In order to share this with others, you need to publish "
        , text "this share. Then everyone you'll send the generated link "
        , text "can access this data."
        ]
    ]


shareLinkExpired : Model -> List (Html Msg)
shareLinkExpired model =
    [ div
        [ classList
            [ ( "invisible", model.topMenu /= TopShare )
            , ( "ui attached warning message segment", True )
            ]
        ]
        [ text "The share has been published, but it is now expired. You can "
        , text "first unpublish and then publish it again."
        ]
    ]


shareLinkPublished : Flags -> Model -> List (Html Msg)
shareLinkPublished flags model =
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
                    (Html.text "Error while encoding to QRCode.")
    in
    [ div
        [ classList
            [ ( "invisible", model.topMenu /= TopShare )
            , ( "ui attached segment", True )
            ]
        ]
        [ text "The share is publicly available at"
        , pre [ class "url" ]
            [ code []
                [ text url
                ]
            ]
        , text "You can share this link to all you'd like to access this data."
        ]
    , case model.mailForm of
        Just mf ->
            Html.map MailFormMsg
                (Comp.MailSend.view
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
                    [ div [ class "ui vertical divider" ] [ text "Or" ]
                    , div [ class "middle aligned row" ]
                        [ div [ class "column" ]
                            [ qrCodeView url
                            ]
                        , div [ class "column" ]
                            [ a
                                [ classList
                                    [ ( "ui primary button", True )
                                    , ( "disabled", not flags.config.mailEnabled )
                                    ]
                                , href "#"
                                , onClick InitMail
                                ]
                                [ text "Send E-Mail"
                                ]
                            ]
                        ]
                    ]
                ]
    ]


messageDiv : Model -> Html Msg
messageDiv model =
    Util.Html.resultMsgMaybe model.message


shareProps : Model -> List (Html Msg)
shareProps model =
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
        [ Html.map YesNoMsg (Comp.YesNoDimmer.view model.yesNoModel)
        , div [ class "ui stackable two column grid" ]
            [ div [ class "column" ]
                [ div [ class "ui items" ]
                    [ property
                        { label = "Name"
                        , content =
                            isEdit model Name
                                |> Maybe.map propertyEdit
                                |> Maybe.withDefault
                                    (propertyDisplay "comment outline icon"
                                        (Maybe.withDefault "" share.name)
                                    )
                        , editAction = Just (ReqEdit Name)
                        }
                    , property
                        { label = "Validity Time"
                        , content =
                            isEdit model Validity
                                |> Maybe.map propertyEdit
                                |> Maybe.withDefault
                                    (propertyDisplay "hourglass half icon"
                                        (Data.ValidityOptions.findValidityItemMillis share.validity
                                            |> Tuple.first
                                        )
                                    )
                        , editAction = Just (ReqEdit Validity)
                        }
                    , property
                        { label = "Max. Views"
                        , content =
                            isEdit model MaxViews
                                |> Maybe.map propertyEdit
                                |> Maybe.withDefault
                                    (propertyDisplay "eye icon" (String.fromInt share.maxViews))
                        , editAction = Just (ReqEdit MaxViews)
                        }
                    , property
                        { label = "Password"
                        , content =
                            isEdit model Password
                                |> Maybe.map propertyEdit
                                |> Maybe.withDefault
                                    (propertyDisplay
                                        (if share.password then
                                            "lock icon"

                                         else
                                            "unlock icon"
                                        )
                                        (if share.password then
                                            "Password Protected"

                                         else
                                            "None"
                                        )
                                    )
                        , editAction = Just (ReqEdit Password)
                        }
                    , property
                        { label = "#/Size"
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
                        { label = "Created"
                        , content =
                            propertyDisplay "calendar icon"
                                (Util.Time.formatDateTime share.created)
                        , editAction = Nothing
                        }
                    ]
                ]
            , div [ class "column" ]
                [ div [ class "ui items" ]
                    [ property
                        { label = "Alias"
                        , content =
                            propertyDisplay "dot circle outline icon" (Maybe.withDefault "-" share.aliasName)
                        , editAction = Nothing
                        }
                    , property
                        { label = "Published on"
                        , content =
                            propertyDisplay (Tuple.first <| publishIconLabel share)
                                (Maybe.map .publishDate share.publishInfo
                                    |> Maybe.map Util.Time.formatDateTime
                                    |> Maybe.withDefault "-"
                                )
                        , editAction = Nothing
                        }
                    , property
                        { label = "Published until"
                        , content =
                            propertyDisplay "hourglass icon"
                                (Maybe.map .publishUntil share.publishInfo
                                    |> Maybe.map Util.Time.formatDateTime
                                    |> Maybe.withDefault "-"
                                )
                        , editAction = Nothing
                        }
                    , property
                        { label = "Last Access"
                        , content =
                            propertyDisplay "calendar outline icon"
                                (Maybe.andThen .lastAccess share.publishInfo
                                    |> Maybe.map Util.Time.formatDateTime
                                    |> Maybe.withDefault "-"
                                )
                        , editAction = Nothing
                        }
                    , property
                        { label = "Views"
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
                [ text "Publish with new Link"
                ]
            , button
                [ type_ "button"
                , class "ui red button"
                , onClick RequestDelete
                ]
                [ i [ class "trash icon" ] []
                , text "Delete"
                ]
            ]
        ]
    ]


property :
    { label : String
    , content : List (Html Msg)
    , editAction : Maybe Msg
    }
    -> Html Msg
property rec =
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
                            , title "Edit"
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


propertyEdit : EditField -> List (Html Msg)
propertyEdit ef =
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
                    , placeholder "Name"
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
                [ Html.map ValidityEditMsg (Comp.ValidityField.view v vm)
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


topMenu : Model -> Html Msg
topMenu model =
    let
        share =
            model.share

        ( publishIcon, label ) =
            publishIconLabel share
    in
    div
        [ classList
            [ ( "ui pointing menu", True )
            , ( "top attached", model.topMenu /= TopClosed )
            ]
        ]
        [ topMenuLink model TopDetail "Details"
        , topMenuLink model TopShare "Share Link"
        , div [ class "right menu" ]
            [ a
                [ classList
                    [ ( "icon link item", True )
                    , ( "active", model.descEdit /= Nothing )
                    ]
                , href "#"
                , title "Edit description"
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


publishIconLabel : ShareDetail -> ( String, String )
publishIconLabel share =
    case isPublished share of
        Unpublished ->
            ( "circle outline icon", "Publish" )

        PublishExpired ->
            ( "red bolt icon", "Unpublish" )

        MaxViewsExceeded ->
            ( "red bolt icon", "Unpublish" )

        PublishOk ->
            ( "green circle icon", "Unpublish" )


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


middleMenu : Model -> Html Msg
middleMenu model =
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
            , title "List View"
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
            , title "Card View"
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


dropzone : Flags -> Model -> Html Msg
dropzone flags model =
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
                , text "Submit"
                ]
            , a
                [ class "item"
                , href "#"
                , onClick ResetFileForm
                ]
                [ i [ class "undo icon" ] []
                , text "Clear"
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
                            "Resume"

                         else
                            "Pause"
                        )
                    ]
                ]
            ]
        , p []
            [ text "All uploads must not be greater than "
            , toFloat flags.config.maxSize
                |> Util.Size.bytesReadable Util.Size.B
                |> text
            , text "."
            ]
        , div
            [ classList
                [ ( "ui error message", True )
                , ( "invisible hidden", model.uploadFormState.success )
                ]
            ]
            [ text model.uploadFormState.message
            ]
        , Html.map DropzoneMsg (Comp.Dropzone2.view viewSettings model.dropzone)
        ]


deleteLoader : Model -> Html Msg
deleteLoader model =
    div
        [ classList
            [ ( "ui dimmer", True )
            , ( "active", model.loader.active )
            ]
        ]
        [ div [ class "ui indeterminate text loader" ]
            [ text model.loader.message
            ]
        ]
