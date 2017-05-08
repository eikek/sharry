module Pages.Login.Data exposing (..)

import Http
import Data exposing (Account)

type Msg
    = Login String
    | Password String
    | TryLogin
    | AuthResult (Result Http.Error Account)
