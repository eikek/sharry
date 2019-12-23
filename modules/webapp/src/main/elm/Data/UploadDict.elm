module Data.UploadDict exposing
    ( UploadDict
    , UploadProgress(..)
    , allDone
    , countDone
    , empty
    , size
    , trackUpload
    , updateFiles
    )

import Data.UploadState exposing (UploadState)
import Dict exposing (Dict)
import File exposing (File)
import Json.Decode as D


type alias UploadDict =
    { selectedFiles : List ( D.Value, File )
    , uploads : Dict Int UploadState
    }


empty : UploadDict
empty =
    { selectedFiles = []
    , uploads = Dict.empty
    }


updateFiles : UploadDict -> List ( D.Value, File ) -> UploadDict
updateFiles model files =
    { model | selectedFiles = files }


type UploadProgress
    = FileProgress Int Int
    | AllProgress Int


size : UploadDict -> Int
size up =
    List.map Tuple.second up.selectedFiles
        |> List.map File.size
        |> List.sum


allDone : UploadDict -> Bool
allDone up =
    let
        ( succ, err ) =
            countDone up
    in
    succ + err == List.length up.selectedFiles


countDone : UploadDict -> ( Int, Int )
countDone { selectedFiles, uploads } =
    let
        tupleAdd t1 t2 =
            ( Tuple.first t1 + Tuple.first t2
            , Tuple.second t1 + Tuple.second t2
            )

        count index file =
            Dict.get index uploads
                |> Maybe.map .state
                |> Maybe.map
                    (\s ->
                        case s of
                            Data.UploadState.Complete ->
                                ( 1, 0 )

                            Data.UploadState.Progress _ _ ->
                                ( 0, 0 )

                            Data.UploadState.Failed _ ->
                                ( 0, 1 )
                    )
                |> Maybe.withDefault ( 0, 0 )
    in
    List.indexedMap count selectedFiles
        |> List.foldl tupleAdd ( 0, 0 )


trackUpload : UploadDict -> UploadState -> ( UploadDict, List UploadProgress )
trackUpload model state =
    let
        next =
            Dict.insert state.file state model.uploads

        sizeOf index file =
            Dict.get index next
                |> Maybe.map .state
                |> Maybe.map
                    (\s ->
                        case s of
                            Data.UploadState.Complete ->
                                File.size file

                            Data.UploadState.Progress n _ ->
                                n

                            Data.UploadState.Failed _ ->
                                File.size file
                    )
                |> Maybe.withDefault 0

        allsize =
            List.unzip model.selectedFiles
                |> Tuple.second
                |> List.map File.size
                |> List.sum

        currsize =
            List.unzip model.selectedFiles
                |> Tuple.second
                |> List.indexedMap sizeOf
                |> List.sum

        mkPercent : Int -> Int -> Int
        mkPercent c t =
            (toFloat c / toFloat t) * 100 |> round

        filePerc =
            case state.state of
                Data.UploadState.Progress cur total ->
                    [ FileProgress state.file (mkPercent cur total)
                    ]

                _ ->
                    []

        allPerc =
            [ AllProgress (mkPercent currsize allsize)
            ]
    in
    ( { model
        | uploads = next
      }
    , filePerc ++ allPerc
    )
