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
import Messages exposing (Messages)
import Page exposing (Page(..))
import Page.Share.Data exposing (Model, Msg(..))


view : Messages -> Flags -> Model -> Html Msg
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
                , text "Create a Share"
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
                    doneMessageBox counts model

                  else
                    controls model
                , Data.Flags.limitsMessage flags
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
                        , text "Details"
                        ]
                    , div
                        [ classList
                            [ ( "content", True )
                            , ( "active", model.showDetails )
                            ]
                        ]
                        [ div [ class "field" ]
                            [ label [] [ text "Description" ]
                            , Html.map DescMsg
                                (Comp.MarkdownInput.view
                                    model.descField
                                    model.descModel
                                )
                            ]
                        , div [ class "two fields" ]
                            [ div [ class "field" ]
                                [ label [] [ text "Name" ]
                                , input
                                    [ type_ "text"
                                    , placeholder "Optional Name"
                                    , onInput SetName
                                    ]
                                    []
                                ]
                            , div [ class "required field" ]
                                [ label [] [ text "Validity" ]
                                , Html.map ValidityMsg
                                    (Comp.ValidityField.view
                                        model.validityField
                                        model.validityModel
                                    )
                                ]
                            ]
                        , div [ class "two fields" ]
                            [ Html.map MaxViewMsg
                                (Comp.IntField.view
                                    model.maxViewField
                                    model.maxViewModel
                                )
                            , div [ class "field" ]
                                [ label [] [ text "Password" ]
                                , Html.map PasswordMsg
                                    (Comp.PasswordInput.view model.passwordField
                                        model.passwordModel
                                    )
                                ]
                            ]
                        ]
                    , div [ class "active ui header title" ]
                        [ i [ class "dropdown icon" ] []
                        , text "Files"
                        ]
                    , Html.map DropzoneMsg
                        (Comp.Dropzone2.view
                            (mkViewSettings model)
                            model.dropzoneModel
                        )
                    ]
                ]
            ]
        ]


doneMessageBox : ( Int, Int ) -> Model -> Html Msg
doneMessageBox ( _, err ) model =
    let
        buttons =
            div [ class "" ]
                [ a
                    [ class "ui primary button"
                    , href "#"
                    , onClick ResetForm
                    ]
                    [ text "New Share"
                    ]
                , a
                    [ class "ui secondary button"
                    , Page.href (DetailPage <| Maybe.withDefault "" model.shareId)
                    ]
                    [ text "Goto Share"
                    ]
                ]

        success =
            div [ class "ui success icon message" ]
                [ i [ class "ui check icon" ] []
                , div [ class "content" ]
                    [ div [ class "ui header" ]
                        [ text "All files uploaded"
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
                        [ text "Some files failed"
                        ]
                    , p []
                        [ text "Some files failed to upload…. "
                        , text "You can go to the share and try uploading them again."
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


controls : Model -> Html Msg
controls model =
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
            , text "Submit"
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
            , text "Clear Files"
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
                text "Resume"

              else
                text "Pause"
            ]
        ]


mkViewSettings : Model -> Comp.Dropzone2.ViewSettings
mkViewSettings model =
    Comp.Dropzone2.mkViewSettings (not model.uploading) model.uploads
