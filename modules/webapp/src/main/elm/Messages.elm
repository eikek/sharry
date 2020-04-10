module Messages exposing
    ( Language(..)
    , Messages
    , allLanguages
    , fromFlags
    , get
    , toIso2
    )

import Data.Flags exposing (Flags)
import Messages.AccountPage
import Messages.AliasPage
import Messages.App
import Messages.DetailPage
import Messages.HomePage
import Messages.LoginPage
import Messages.NewInvitePage
import Messages.RegisterPage
import Messages.SettingsPage
import Messages.SharePage
import Messages.UploadPage


type Language
    = English


allLanguages : List Language
allLanguages =
    [ English
    ]


{-| Get a ISO-3166-1 code of the given lanugage.
-}
toIso2 : Language -> String
toIso2 lang =
    get lang |> .iso2


{-| Return the Language from given iso2 code. If the iso2 code is not
known, return Nothing.
-}
readIso2 : String -> Maybe Language
readIso2 iso =
    let
        isIso lang =
            iso == toIso2 lang
    in
    List.filter isIso allLanguages
        |> List.head


{-| Return the Language from the given iso2 code. If the iso2 code is
not known, return English as a default.
-}
fromIso2 : String -> Language
fromIso2 iso =
    readIso2 iso
        |> Maybe.withDefault English



-- Messages


{-| The messages record contains all strings used in the application.
-}
type alias Messages =
    { iso2 : String
    , label : String
    , flagIcon : String
    , app : Messages.App.Texts
    , login : Messages.LoginPage.Texts
    , register : Messages.RegisterPage.Texts
    , account : Messages.AccountPage.Texts
    , aliasPage : Messages.AliasPage.Texts
    , detail : Messages.DetailPage.Texts
    , share : Messages.SharePage.Texts
    , home : Messages.HomePage.Texts
    , upload : Messages.UploadPage.Texts
    , newInvite : Messages.NewInvitePage.Texts
    , settings : Messages.SettingsPage.Texts
    }


get : Language -> Messages
get lang =
    case lang of
        English ->
            gb


fromFlags : Flags -> Messages
fromFlags flags =
    Maybe.map fromIso2 flags.language
        |> Maybe.withDefault English
        |> get


gb : Messages
gb =
    { iso2 = "gb"
    , label = "English"
    , flagIcon = "gb uk flag"
    , app = Messages.App.gb
    , login = Messages.LoginPage.gb
    , register = Messages.RegisterPage.gb
    , account = Messages.AccountPage.gb
    , aliasPage = Messages.AliasPage.gb
    , detail = Messages.DetailPage.gb
    , share = Messages.SharePage.gb
    , home = Messages.HomePage.gb
    , upload = Messages.UploadPage.gb
    , newInvite = Messages.NewInvitePage.gb
    , settings = Messages.SettingsPage.gb
    }
