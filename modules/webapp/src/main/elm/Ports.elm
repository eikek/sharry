port module Ports exposing (..)

import Data exposing (..)
import Resumable

-- Ports

port setAccount : Account -> Cmd msg
port removeAccount : Account -> Cmd msg

port makeRandomString: String -> Cmd msg
port randomString: (String -> msg) -> Sub msg

port setProgress: (String, Float, Bool) -> Cmd msg


port makeResumable: Resumable.Config -> Cmd msg
port resumableHandle: ((String, Resumable.Handle) -> msg) -> Sub msg

port resumableRebind: Resumable.Handle -> Cmd msg

port resumableStart: Resumable.Handle -> Cmd msg
port resumablePause: Resumable.Handle -> Cmd msg
port resumableCancel: Resumable.Handle -> Cmd msg
port resumableRetry: (Resumable.Handle, List String) -> Cmd msg

port resumableFileAdded: ((String, Resumable.File) -> msg) -> Sub msg
port resumableFileSuccess: ((String, Resumable.File) -> msg) -> Sub msg
port resumableStarted: (String -> msg) -> Sub msg
port resumablePaused: (String -> msg) -> Sub msg
port resumableProgress: ((String, Float) -> msg) -> Sub msg
port resumableComplete: (String -> msg) -> Sub msg
port resumableError: ((String, String, Resumable.File) -> msg) -> Sub msg

port resumableMaxFileSizeError: ((String, Resumable.File) -> msg) -> Sub msg
port resumableMaxFilesError: ((String, Resumable.File) -> msg) -> Sub msg

port reloadPage: () -> Cmd msg
