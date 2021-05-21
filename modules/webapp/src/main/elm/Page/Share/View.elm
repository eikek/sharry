module Page.Share.View exposing (view)

import Comp.Basic as B
import Comp.Dropzone2
import Comp.IntField
import Comp.MarkdownInput
import Comp.MenuBar as MB
import Comp.PasswordInput
import Comp.ValidityField
import Data.Flags exposing (Flags)
import Data.UploadDict exposing (countDone)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Messages.SharePage exposing (Texts)
import Page exposing (Page(..))
import Page.Share.Data exposing (Model, Msg(..))
import Styles as S


view : Texts -> Flags -> Model -> Html Msg
view texts flags model =
    let
        counts =
            countDone model.uploads

        allDone =
            model.shareId
                /= Nothing
                && Tuple.first counts
                + Tuple.second counts
                == List.length model.uploads.selectedFiles
    in
    div
        [ class S.content
        , class "flex flex-col"
        ]
        [ h1 [ class S.header1 ]
            [ i [ class "fa fa-share-alt mr-2" ] []
            , text texts.createShare
            ]
        , if allDone then
            doneMessageBox counts texts model

          else
            controls texts model
        , Data.Flags.limitsMessage
            texts
            flags
            [ class "py-2" ]
        , div
            [ class S.errorMessage
            , classList
                [ ( "hidden", model.formState.success && Tuple.second counts <= 0 )
                ]
            ]
            [ text model.formState.message
            ]
        , div [ class "flex flex-col" ]
            [ div [ class "mb-4" ]
                [ Html.map DropzoneMsg
                    (Comp.Dropzone2.view
                        texts.dropzone
                        (mkViewSettings model)
                        model.dropzoneModel
                    )
                ]
            , div [ class "mb-4" ]
                [ label [ class S.inputLabel ]
                    [ text texts.description
                    ]
                , Html.map DescMsg
                    (Comp.MarkdownInput.view
                        texts.markdownInput
                        [ ( S.border ++ " py-1 px-1", True ) ]
                        model.descField
                        model.descModel
                    )
                ]
            , div [ class "mb-4" ]
                [ label [ class S.inputLabel ]
                    [ text texts.name
                    ]
                , input
                    [ type_ "text"
                    , placeholder texts.namePlaceholder
                    , class S.textInput
                    , onInput SetName
                    ]
                    []
                ]
            , div [ class "mb-4" ]
                [ label [ class S.inputLabel ]
                    [ text texts.validity
                    , B.inputRequired
                    ]
                , Html.map ValidityMsg
                    (Comp.ValidityField.view
                        texts.validityField
                        model.validityField
                        model.validityModel
                    )
                ]
            , Html.map MaxViewMsg
                (Comp.IntField.view
                    model.maxViewField
                    texts.intField
                    texts.maxPublicViews
                    model.maxViewModel
                )
            , div [ class "mb-4" ]
                [ label [ class S.inputLabel ]
                    [ text texts.password
                    ]
                , Html.map PasswordMsg
                    (Comp.PasswordInput.view
                        { placeholder = "" }
                        model.passwordField
                        False
                        model.passwordModel
                    )
                ]
            ]
        ]


doneMessageBox : ( Int, Int ) -> Texts -> Model -> Html Msg
doneMessageBox ( _, err ) texts model =
    let
        buttons =
            div [ class "flex flex-row space-x-2" ]
                [ a
                    [ class S.primaryButton
                    , href "#"
                    , onClick ResetForm
                    ]
                    [ text texts.newShare
                    ]
                , a
                    [ class S.secondaryButton
                    , Page.href (DetailPage <| Maybe.withDefault "" model.shareId)
                    ]
                    [ text texts.gotoShare
                    ]
                ]

        success =
            div
                [ class S.successMessage
                , class "flex flex-row items-center"
                ]
                [ i [ class "fa fa-check text-2xl mr-2" ] []
                , div [ class "flex flex-col" ]
                    [ div [ class S.header2 ]
                        [ text texts.allFilesUploaded
                        ]
                    , buttons
                    ]
                ]

        error =
            div
                [ class S.errorMessage
                , class "flex flex-row items-center"
                ]
                [ i [ class "fa fa-meh text-2xl mr-2" ] []
                , div [ class "flex flex-col" ]
                    [ div [ class S.header2 ]
                        [ text texts.someFilesFailedHeader
                        ]
                    , p [ class "mb-2" ]
                        [ text texts.someFilesFailedText
                        , text texts.someFilesFailedTextAddon
                        ]
                    , buttons
                    ]
                ]
    in
    if err > 0 then
        error

    else
        success


controls : Texts -> Model -> Html Msg
controls texts model =
    MB.view
        { start =
            [ MB.CustomElement <|
                B.primaryButton
                    { handler = onClick Submit
                    , disabled = model.uploading
                    , label = texts.submit
                    , icon = "fa fa-upload"
                    , attrs = [ href "#" ]
                    , responsive = False
                    }
            , MB.CustomElement <|
                B.secondaryButton
                    { handler = onClick ClearFiles
                    , disabled = model.uploading
                    , label = texts.clearFiles
                    , icon = "fa fa-undo"
                    , attrs = [ href "#" ]
                    , responsive = True
                    }
            ]
        , end =
            [ MB.CustomElement <|
                B.secondaryBasicButton
                    { handler = onClick StartStopUpload
                    , disabled = not model.uploading
                    , label =
                        if model.uploadPaused then
                            texts.resume

                        else
                            texts.pause
                    , icon =
                        if model.uploadPaused then
                            "fa fa-play sm:mr-2"

                        else
                            "fa fa-pause sm:mr-2"
                    , attrs = [ href "#" ]
                    , responsive = True
                    }
            ]
        , rootClasses = ""
        , sticky = True
        }


mkViewSettings : Model -> Comp.Dropzone2.ViewSettings
mkViewSettings model =
    Comp.Dropzone2.mkViewSettings (not model.uploading) model.uploads
