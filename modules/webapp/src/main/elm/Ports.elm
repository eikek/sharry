port module Ports exposing (..)

import Api.Model.AuthResult exposing (AuthResult)
import Json.Decode as D
import Language exposing (Language)
import Messages


port setAccount : AuthResult -> Cmd msg


port removeAccount : () -> Cmd msg


port submitFiles : D.Value -> Cmd msg


{-| Information from JS about an upload that is currently in progress
or completed.

The JSON data is read into a [UploadState](#Data.UploadState) data
type.

-}
port uploadState : (D.Value -> msg) -> Sub msg


{-| Requests to stop the current upload.
-}
port stopUpload : String -> Cmd msg


port startUpload : String -> Cmd msg


{-| Callback from the JS side to tell when a call to `stopUpload` has
completed.
-}
port uploadStopped : (Maybe String -> msg) -> Sub msg


{-| Scroll to the top
-}
port scrollTop : () -> Cmd msg


port scrollToElem : String -> Cmd msg


port setLanguage : String -> Cmd msg


setLang : Language -> Cmd msg
setLang lang =
    setLanguage (Messages.toIso2 lang)


port receiveLanguage : (String -> msg) -> Sub msg


port initClipboard : ( String, String ) -> Cmd msg
