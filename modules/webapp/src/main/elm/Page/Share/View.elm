module Page.Share.View exposing (view)

import Comp.Dropzone2
import Comp.IntField
import Comp.MarkdownInput
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
    div []
        [ div [ class "ui container" ]
            [ h1 [ class "ui dividing header" ]
                [ i [ class "ui share alternate icon" ] []
                , text texts.createShare
                ]
            ]
        , div [ class "ui container" ]
            [ p [] []
            , div
                [ classList
                    [ ( "ui small form", True )
                    , ( "error", not model.formState.success || Tuple.second counts > 0 )
                    , ( "success", Tuple.second counts == 0 )
                    ]
                ]
                [ if allDone then
                    doneMessageBox counts texts model

                  else
                    controls texts model
                , Data.Flags.limitsMessage
                    texts
                    flags
                    [ class "ui info message" ]
                , div [ class "ui error message" ]
                    [ text model.formState.message
                    ]
                , div [ class "ui accordion" ]
                    [ div
                        [ classList
                            [ ( "ui header title", True )
                            , ( "active", model.showDetails )
                            ]
                        , onClick ToggleDetails
                        ]
                        [ i [ class "dropdown icon" ] []
                        , text texts.details
                        ]
                    , div
                        [ classList
                            [ ( "content", True )
                            , ( "active", model.showDetails )
                            ]
                        ]
                        [ div [ class "field" ]
                            [ label [] [ text texts.description ]
                            , Html.map DescMsg
                                (Comp.MarkdownInput.view
                                    texts.markdownInput
                                    model.descField
                                    model.descModel
                                )
                            ]
                        , div [ class "two fields" ]
                            [ div [ class "field" ]
                                [ label [] [ text texts.name ]
                                , input
                                    [ type_ "text"
                                    , placeholder texts.namePlaceholder
                                    , onInput SetName
                                    ]
                                    []
                                ]
                            , div [ class "required field" ]
                                [ label [] [ text texts.validity ]
                                , Html.map ValidityMsg
                                    (Comp.ValidityField.view
                                        texts.validityField
                                        model.validityField
                                        model.validityModel
                                    )
                                ]
                            ]
                        , div [ class "two fields" ]
                            [ Html.map MaxViewMsg
                                (Comp.IntField.view
                                    model.maxViewField
                                    texts.intField
                                    texts.maxPublicViews
                                    model.maxViewModel
                                )
                            , div [ class "field" ]
                                [ label [] [ text texts.password ]
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
                    , div [ class "active ui header title" ]
                        [ i [ class "dropdown icon" ] []
                        , text texts.files
                        ]
                    , Html.map DropzoneMsg
                        (Comp.Dropzone2.view
                            texts.dropzone
                            (mkViewSettings model)
                            model.dropzoneModel
                        )
                    ]
                ]
            ]
        ]


doneMessageBox : ( Int, Int ) -> Texts -> Model -> Html Msg
doneMessageBox ( _, err ) texts model =
    let
        buttons =
            div [ class "" ]
                [ a
                    [ class "ui primary button"
                    , href "#"
                    , onClick ResetForm
                    ]
                    [ text texts.newShare
                    ]
                , a
                    [ class "ui secondary button"
                    , Page.href (DetailPage <| Maybe.withDefault "" model.shareId)
                    ]
                    [ text texts.gotoShare
                    ]
                ]

        success =
            div [ class "ui success icon message" ]
                [ i [ class "ui check icon" ] []
                , div [ class "content" ]
                    [ div [ class "ui header" ]
                        [ text texts.allFilesUploaded
                        ]
                    , div [ class "ui divider" ] []
                    , buttons
                    ]
                ]

        error =
            div [ class "ui error icon message" ]
                [ i [ class "ui meh icon" ] []
                , div [ class "content" ]
                    [ div [ class "header" ]
                        [ text texts.someFilesFailedHeader
                        ]
                    , p []
                        [ text texts.someFilesFailedText
                        , text texts.someFilesFailedTextAddon
                        ]
                    , div [ class "ui divider" ] []
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
    div
        [ class "field"
        ]
        [ a
            [ classList
                [ ( "ui primary button", True )
                , ( "disabled", model.uploading )
                ]
            , href "#"
            , onClick Submit
            ]
            [ i [ class "upload icon" ] []
            , text texts.submit
            ]
        , a
            [ onClick ClearFiles
            , href "#"
            , classList
                [ ( "ui basic button", True )
                , ( "disabled", model.uploading )
                ]
            ]
            [ i [ class "undo icon" ] []
            , text texts.clearFiles
            ]
        , a
            [ classList
                [ ( "ui right floated basic button", True )
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
            , if model.uploadPaused then
                text texts.resume

              else
                text texts.pause
            ]
        ]


mkViewSettings : Model -> Comp.Dropzone2.ViewSettings
mkViewSettings model =
    Comp.Dropzone2.mkViewSettings (not model.uploading) model.uploads
