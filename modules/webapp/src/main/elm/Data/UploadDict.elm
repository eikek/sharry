module Data.UploadDict exposing
    ( UploadDict
    , UploadProgress(..)
    , allDone
    , allProgress
    , countDone
    , empty
    , size
    , trackUpload
    , updateFiles
    )

import Data.Percent
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


allProgress : UploadDict -> Int
allProgress up =
    let
        sizeOf index file =
            Dict.get index up.uploads
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
            List.unzip up.selectedFiles
                |> Tuple.second
                |> List.map File.size
                |> List.sum

        currsize =
            List.unzip up.selectedFiles
                |> Tuple.second
                |> List.indexedMap sizeOf
                |> List.sum
    in
    Data.Percent.mkPercent currsize allsize


countDone : UploadDict -> ( Int, Int )
countDone { selectedFiles, uploads } =
    let
        tupleAdd t1 t2 =
            ( Tuple.first t1 + Tuple.first t2
            , Tuple.second t1 + Tuple.second t2
            )

        count index _ =
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


trackUpload : UploadDict -> UploadState -> UploadDict
trackUpload model state =
    let
        next =
            Dict.insert state.file state model.uploads
    in
    { model | uploads = next }
