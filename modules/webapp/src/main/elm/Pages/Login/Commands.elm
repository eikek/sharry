module Pages.Login.Commands exposing (..)

import Http
import Json.Encode as Encode
import Data exposing (Account, accountDecoder)
import Pages.Login.Model exposing (Model)
import Pages.Login.Data as LoginData exposing (Msg)

authenticate: Model -> Cmd Msg
authenticate model =
    Http.post (authUrl model) (Http.jsonBody (userPassJson model)) accountDecoder
        |> Http.send LoginData.AuthResult

authUrl: Model -> String
authUrl model =
    model.loginUrl


userPassJson: Model -> Encode.Value
userPassJson model =
    Encode.object
    [ ("login", Encode.string model.login)
    , ("pass", Encode.string model.password)
    ]
