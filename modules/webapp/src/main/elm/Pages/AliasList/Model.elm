module Pages.AliasList.Model exposing (..)

import Data exposing (Alias, RemoteConfig, RemoteUrls)
import Widgets.AliasList as AliasList

type alias Model =
    {aliasList: AliasList.Model
    ,urls: RemoteUrls
    }

emptyModel: RemoteConfig -> Model
emptyModel cfg =
    Model (AliasList.emptyModel cfg) cfg.urls

makeModel: RemoteConfig -> List Alias -> Model
makeModel cfg alia =
    Model (AliasList.makeModel cfg alia) cfg.urls

type Msg = AliasListMsg AliasList.Msg
