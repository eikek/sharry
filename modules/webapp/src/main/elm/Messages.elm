module Messages exposing
    ( Messages
    , fromFlags
    , get
    , toIso2
    )

import Data.Flags exposing (Flags)
import Language exposing (Language(..), allLanguages)
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


{-| The messages record contains all strings used in the application.
-}
type alias Messages =
    { lang : Language
    , iso2 : String
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

        German ->
            de

        French ->
            fr

        Japanese ->
            ja

        Czech ->
            cz

        Spanish ->
            es

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


fromFlags : Flags -> Messages
fromFlags flags =
    let
        iso =
            case flags.language of
                Just lang ->
                    lang

                Nothing ->
                    flags.config.defaultLanguage
    in
    fromIso2 iso
        |> get



--- Messages Definitions


es : Messages
es =
    { lang = Spanish
    , iso2 = "es"
    , label = "Español"
    , flagIcon = "fi fi-es"
    , app = Messages.App.es
    , login = Messages.LoginPage.es
    , register = Messages.RegisterPage.es
    , account = Messages.AccountPage.es
    , aliasPage = Messages.AliasPage.es
    , detail = Messages.DetailPage.es
    , share = Messages.SharePage.es
    , home = Messages.HomePage.es
    , upload = Messages.UploadPage.es
    , newInvite = Messages.NewInvitePage.es
    , settings = Messages.SettingsPage.es
    }


gb : Messages
gb =
    { lang = English
    , iso2 = "gb"
    , label = "English"
    , flagIcon = "fi fi-gb"
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


de : Messages
de =
    { lang = German
    , iso2 = "de"
    , label = "Deutsch"
    , flagIcon = "fi fi-de"
    , app = Messages.App.de
    , login = Messages.LoginPage.de
    , register = Messages.RegisterPage.de
    , account = Messages.AccountPage.de
    , aliasPage = Messages.AliasPage.de
    , detail = Messages.DetailPage.de
    , share = Messages.SharePage.de
    , home = Messages.HomePage.de
    , upload = Messages.UploadPage.de
    , newInvite = Messages.NewInvitePage.de
    , settings = Messages.SettingsPage.de
    }


fr : Messages
fr =
    { lang = French
    , iso2 = "fr"
    , label = "Français"
    , flagIcon = "fi fi-fr"
    , app = Messages.App.fr
    , login = Messages.LoginPage.fr
    , register = Messages.RegisterPage.fr
    , account = Messages.AccountPage.fr
    , aliasPage = Messages.AliasPage.fr
    , detail = Messages.DetailPage.fr
    , share = Messages.SharePage.fr
    , home = Messages.HomePage.fr
    , upload = Messages.UploadPage.fr
    , newInvite = Messages.NewInvitePage.fr
    , settings = Messages.SettingsPage.fr
    }


ja : Messages
ja =
    { lang = Japanese
    , iso2 = "ja"
    , label = "日本語"
    , flagIcon = "fi fi-jp"
    , app = Messages.App.ja
    , login = Messages.LoginPage.ja
    , register = Messages.RegisterPage.ja
    , account = Messages.AccountPage.ja
    , aliasPage = Messages.AliasPage.ja
    , detail = Messages.DetailPage.ja
    , share = Messages.SharePage.ja
    , home = Messages.HomePage.ja
    , upload = Messages.UploadPage.ja
    , newInvite = Messages.NewInvitePage.ja
    , settings = Messages.SettingsPage.ja
    }

cz : Messages
cz =
    { lang = Czech
    , iso2 = "cz"
    , label = "Čeština"
    , flagIcon = "fi fi-cz"
    , app = Messages.App.cz
    , login = Messages.LoginPage.cz
    , register = Messages.RegisterPage.cz
    , account = Messages.AccountPage.cz
    , aliasPage = Messages.AliasPage.cz
    , detail = Messages.DetailPage.cz
    , share = Messages.SharePage.cz
    , home = Messages.HomePage.cz
    , upload = Messages.UploadPage.cz
    , newInvite = Messages.NewInvitePage.cz
    , settings = Messages.SettingsPage.cz
    }
