module Pages.UploadList.Update exposing (..)

import Pages.UploadList.Model exposing (..)
import Widgets.UploadList as UploadList

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UploadListMsg msg ->
            let
                (m, c) = UploadList.update msg model.uploadList
            in
                {model | uploadList = m} ! [Cmd.map UploadListMsg c]
