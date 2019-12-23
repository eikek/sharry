module Util.Share exposing (splitDescription, validate)

import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.ShareDetail exposing (ShareDetail)
import Data.Flags exposing (Flags)
import Data.UploadDict exposing (UploadDict)


splitDescription : ShareDetail -> ( String, String )
splitDescription share =
    let
        fallback =
            Maybe.map (\n -> "# " ++ n) share.name
                |> Maybe.withDefault "# Your Share"

        desc =
            Maybe.map String.trim share.description
                |> Maybe.withDefault ""

        lines =
            String.lines desc
    in
    case lines of
        [] ->
            ( fallback, desc )

        first :: rest ->
            if String.startsWith "#" (String.trim first) then
                ( first, String.join "\n" rest )

            else
                ( fallback, desc )


validate :
    Flags
    -> Maybe ShareDetail
    -> { m | descField : String, uploads : UploadDict }
    -> BasicResult
validate flags mshare model =
    if model.descField == "" && model.uploads.selectedFiles == [] then
        BasicResult False "Either some files or a description must be provided."

    else
        let
            nsz =
                Data.UploadDict.size model.uploads

            esz =
                Maybe.map .files mshare
                    |> Maybe.withDefault []
                    |> List.map .size
                    |> List.sum
        in
        if (nsz + esz) > flags.config.maxSize then
            BasicResult False "Upload is too large."

        else
            BasicResult True ""
