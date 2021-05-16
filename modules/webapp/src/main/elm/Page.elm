module Page exposing
    ( Page(..)
    , fromUrl
    , goto
    , href
    , isAdmin
    , isFixedHeight
    , isOpen
    , isSecured
    , loginPage
    , loginPageReferrer
    , pageFromString
    , pageToString
    , set
    )

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, oneOf, s, string)
import Url.Parser.Query as Query
import Util.Maybe


type Page
    = HomePage
    | LoginPage ( Maybe String, Bool )
    | RegisterPage
    | NewInvitePage
    | InfoPage Int
    | AccountPage (Maybe String)
    | AliasPage (Maybe String)
    | UploadPage
    | SharePage
    | OpenSharePage String
    | SettingsPage
    | DetailPage String
    | OpenDetailPage String


isSecured : Page -> Bool
isSecured page =
    case page of
        HomePage ->
            True

        LoginPage _ ->
            False

        RegisterPage ->
            False

        NewInvitePage ->
            True

        InfoPage _ ->
            False

        AccountPage _ ->
            True

        AliasPage _ ->
            True

        UploadPage ->
            True

        SharePage ->
            True

        OpenSharePage _ ->
            False

        SettingsPage ->
            True

        DetailPage _ ->
            True

        OpenDetailPage _ ->
            False


isFixedHeight : Page -> Bool
isFixedHeight page =
    case page of
        HomePage ->
            True

        LoginPage _ ->
            True

        RegisterPage ->
            True

        _ ->
            False


isAdmin : Page -> Bool
isAdmin page =
    case page of
        NewInvitePage ->
            True

        AccountPage _ ->
            True

        _ ->
            False


isOpen : Page -> Bool
isOpen page =
    not (isSecured page || isAdmin page)


loginPageReferrer : Page -> ( Maybe Page, Bool )
loginPageReferrer page =
    case page of
        LoginPage ( r, flag ) ->
            ( Maybe.andThen pageFromString r, flag )

        _ ->
            ( Nothing, False )


loginPage : Page -> Page
loginPage p =
    case p of
        LoginPage _ ->
            LoginPage ( Nothing, False )

        _ ->
            LoginPage ( Just (pageToString p), False )


pageToString : Page -> String
pageToString page =
    case page of
        HomePage ->
            "/app/home"

        LoginPage ( referer, oauth ) ->
            Maybe.map (\p -> "?r=" ++ p) referer
                |> Maybe.withDefault ""
                |> (++) "/app/login"

        RegisterPage ->
            "/app/register"

        NewInvitePage ->
            "/app/newinvite"

        InfoPage n ->
            "/app/info/" ++ String.fromInt n

        AccountPage mid ->
            let
                path =
                    "/app/account"
            in
            Maybe.map (\id -> path ++ "/" ++ id) mid
                |> Maybe.withDefault path

        AliasPage mid ->
            let
                path =
                    "/app/alias"
            in
            Maybe.map (\id -> path ++ "/" ++ id) mid
                |> Maybe.withDefault path

        UploadPage ->
            "/app/uploads"

        SharePage ->
            "/app/share"

        OpenSharePage id ->
            "/app/share/" ++ id

        SettingsPage ->
            "/app/settings"

        DetailPage id ->
            "/app/upload/" ++ id

        OpenDetailPage id ->
            "/app/open/" ++ id


pageFromString : String -> Maybe Page
pageFromString str =
    let
        urlNormed =
            if String.startsWith str "http" then
                str

            else
                "http://somehost" ++ str

        url =
            Url.fromString urlNormed
    in
    Maybe.andThen (Parser.parse parser) url


href : Page -> Attribute msg
href page =
    Attr.href (pageToString page)


goto : Page -> Cmd msg
goto page =
    Nav.load (pageToString page)


set : Nav.Key -> Page -> Cmd msg
set key page =
    Nav.pushUrl key (pageToString page)


pathPrefix : String
pathPrefix =
    "app"


parser : Parser (Page -> a) a
parser =
    oneOf
        [ Parser.map HomePage Parser.top
        , Parser.map HomePage (s pathPrefix </> s "home")
        , Parser.map LoginPage (s pathPrefix </> s "login" <?> loginPageParser)
        , Parser.map RegisterPage (s pathPrefix </> s "register")
        , Parser.map NewInvitePage (s pathPrefix </> s "newinvite")
        , Parser.map InfoPage (s pathPrefix </> s "info" </> Parser.int)
        , Parser.map (\s -> AccountPage (Just s)) (s pathPrefix </> s "account" </> string)
        , Parser.map (AccountPage Nothing) (s pathPrefix </> s "account")
        , Parser.map (\s -> AliasPage (Just s)) (s pathPrefix </> s "alias" </> string)
        , Parser.map (AliasPage Nothing) (s pathPrefix </> s "alias")
        , Parser.map UploadPage (s pathPrefix </> s "uploads")
        , Parser.map DetailPage (s pathPrefix </> s "upload" </> string)
        , Parser.map OpenSharePage (s pathPrefix </> s "share" </> string)
        , Parser.map SharePage (s pathPrefix </> s "share")
        , Parser.map SettingsPage (s pathPrefix </> s "settings")
        , Parser.map OpenDetailPage (s pathPrefix </> s "open" </> string)
        ]


fromUrl : Url -> Maybe Page
fromUrl url =
    Parser.parse parser url


loginPageOAuthQuery : Query.Parser Bool
loginPageOAuthQuery =
    Query.map Util.Maybe.nonEmpty (Query.string "oauth")


loginPageReferrerQuery : Query.Parser (Maybe String)
loginPageReferrerQuery =
    Query.string "r"


loginPageParser : Query.Parser ( Maybe String, Bool )
loginPageParser =
    Query.map2 Tuple.pair loginPageReferrerQuery loginPageOAuthQuery
