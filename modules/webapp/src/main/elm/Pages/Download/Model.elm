module Pages.Download.Model exposing (..)

import Data exposing (Account, UploadInfo, RemoteUrls)
import Widgets.DownloadView as DownloadView

type alias Model =
    {uploadViewModel: Maybe DownloadView.Model
    }

emptyModel: Model
emptyModel = Model Nothing

makeModel: UploadInfo -> RemoteUrls -> Maybe Account -> Model
makeModel um urls acc =
    Model (Just (DownloadView.makeModel um urls acc))


type Msg
    = DownloadViewMsg DownloadView.Msg
