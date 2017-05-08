module Resumable.Update exposing (..)

import Resumable exposing (..)
import Ports

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Initialize cfg ->
            model ! [ Ports.makeResumable {cfg | handle = model.handle} ]

        SetHandle handle ->
            {model | handle = Just handle} ! []

        FileAdded file ->
            {model | files = file :: model.files, errorFiles = []} ! []

        FileError file msg ->
            {model | errorFiles = (file, msg) :: model.errorFiles} ! []

        FileSuccess file ->
            let
                notFile = \f -> f.uniqueIdentifier /= file.uniqueIdentifier
            in
            {model | errorFiles = List.filter (Tuple.first >> notFile) model.errorFiles} ! []

        Progress percent ->
            {model | progress = percent, state = Uploading} ! []

        UploadComplete ->
            {model | state = Completed, errorFiles = []} ! []

        UploadStarted ->
            {model | state = Uploading, errorFiles = []} ! []

        UploadPaused ->
            {model | state = Paused} ! []
