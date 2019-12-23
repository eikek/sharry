module Page.OpenShare.View exposing (view)

import Comp.Dropzone2
import Comp.MarkdownInput
import Data.Flags exposing (Flags)
import Data.UploadDict exposing (countDone)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Page exposing (Page(..))
import Page.OpenShare.Data exposing (Model, Msg(..))


view : Flags -> String -> Model -> Html Msg
view flags id model =
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
                [ i [ class "ui upload icon" ] []
                , text "Send files"
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
                , div [ class "field" ]
                    [ label [] [ text "Description" ]
                    , Html.map DescMsg
                        (Comp.MarkdownInput.view
                            model.descField
                            model.descModel
                        )
                    ]
                , Html.map DropzoneMsg
                    (Comp.Dropzone2.view
                        (mkViewSettings model)
                        model.dropzoneModel
                    )
                ]
            ]
        ]


doneMessageBox : ( Int, Int ) -> Model -> Html Msg
doneMessageBox ( succ, err ) model =
    let
        buttons =
            div [ class "" ]
                [ a
                    [ class "ui primary button"
                    , href "#"
                    , onClick ResetForm
                    ]
                    [ text "Send more files"
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
                        [ text "Some files failed to upload…. You can try uploading them again."
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
        [ button
            [ type_ "button"
            , classList
                [ ( "ui primary button", True )
                , ( "disabled", model.uploading )
                ]
            , onClick Submit
            ]
            [ text "Submit"
            ]
        , button
            [ type_ "button"
            , onClick ClearFiles
            , classList
                [ ( "ui button", True )
                , ( "disabled", model.uploading )
                ]
            ]
            [ text "Clear Files"
            ]
        , button
            [ type_ "button"
            , classList
                [ ( "ui right floated button", True )
                , ( "disabled", not model.uploading )
                ]
            , onClick StartStopUpload
            ]
            [ if model.uploadPaused then
                text "Resume"

              else
                text "Pause"
            ]
        ]


mkViewSettings : Model -> Comp.Dropzone2.ViewSettings
mkViewSettings model =
    Comp.Dropzone2.mkViewSettings (not model.uploading) model.uploads
