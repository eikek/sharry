module Data.Flags exposing (..)

import Api.Model.AppConfig exposing (AppConfig)
import Api.Model.AuthResult exposing (AuthResult)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.SharePage exposing (Texts)
import Page exposing (Page)
import Util.Size


type alias Flags =
    { account : Maybe AuthResult
    , language : Maybe String
    , uiTheme : Maybe String
    , config : AppConfig
    }


isOAuthAutoRedirect : Flags -> Bool
isOAuthAutoRedirect flags =
    flags.config.oauthAutoRedirect && flags.config.oauthOnly


isProxyAutoRedirect : Flags -> Bool
isProxyAutoRedirect flags =
    flags.config.oauthAutoRedirect && flags.config.proxyOnly


isAutoRedirect : Flags -> Bool
isAutoRedirect flags =
    isOAuthAutoRedirect flags || isProxyAutoRedirect flags


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


limitsMessage : Texts -> Flags -> List (Html.Attribute msg) -> Html msg
limitsMessage texts flags attr =
    let
        size =
            toFloat flags.config.maxSize
                |> Util.Size.bytesReadable Util.Size.B
    in
    div attr
        [ texts.uploadsUpTo size |> text
        ]


initialPage : Flags -> Page
initialPage flags =
    "/app/"
        ++ flags.config.initialPage
        |> Page.pageFromString
        |> Maybe.withDefault Page.HomePage
