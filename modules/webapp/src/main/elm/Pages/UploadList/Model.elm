module Pages.UploadList.Model exposing (..)

import Data exposing (Upload, RemoteUrls)
import Widgets.UploadList as UploadList

type alias Model =
    { uploadList: UploadList.Model
    }

emptyModel: RemoteUrls -> Model
emptyModel urls =
    Model (UploadList.emptyModel urls)

makeModel: RemoteUrls -> List Upload -> Model
makeModel urls up =
    Model (UploadList.makeModel urls up)

type Msg = UploadListMsg UploadList.Msg
