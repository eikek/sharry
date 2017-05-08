module Pages.AliasList.Model exposing (..)

import Data exposing (Alias, RemoteUrls)
import Widgets.AliasList as AliasList

type alias Model =
    {aliasList: AliasList.Model
    ,urls: RemoteUrls
    }

emptyModel: RemoteUrls -> Model
emptyModel urls =
    Model (AliasList.emptyModel urls) urls

makeModel: RemoteUrls -> List Alias -> Model
makeModel urls alia =
    Model (AliasList.makeModel urls alia) urls

type Msg = AliasListMsg AliasList.Msg
