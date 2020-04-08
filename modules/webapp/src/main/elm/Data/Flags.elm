module Data.Flags exposing (..)

import Api.Model.AppConfig exposing (AppConfig)
import Api.Model.AuthResult exposing (AuthResult)
import Html exposing (..)
import Html.Attributes exposing (..)
import Util.Size


type alias Flags =
    { account : Maybe AuthResult
    , language : Maybe String
    , config : AppConfig
    }


getToken : Flags -> Maybe String
getToken flags =
    flags.account
        |> Maybe.andThen (\a -> a.token)


withAccount : Flags -> AuthResult -> Flags
withAccount flags acc =
    { flags | account = Just acc }


withoutAccount : Flags -> Flags
withoutAccount flags =
    { flags | account = Nothing }


limitsMessage : Flags -> List (Html.Attribute msg) -> Html msg
limitsMessage flags attr =
    div attr
        [ text "Uploads are possible up to "
        , toFloat flags.config.maxSize
            |> Util.Size.bytesReadable Util.Size.B
            |> text
        , text "."
        ]
