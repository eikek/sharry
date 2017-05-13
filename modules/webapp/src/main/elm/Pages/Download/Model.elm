module Pages.Download.Model exposing (..)

import Data exposing (Account, UploadInfo, RemoteConfig)
import Widgets.DownloadView as DownloadView

type alias Model =
    {uploadViewModel: Maybe DownloadView.Model
    }

emptyModel: Model
emptyModel = Model Nothing

makeModel: UploadInfo -> RemoteConfig -> Maybe Account -> Model
makeModel um cfg acc =
    Model (Just (DownloadView.makeModel um cfg acc))


type Msg
    = DownloadViewMsg DownloadView.Msg
