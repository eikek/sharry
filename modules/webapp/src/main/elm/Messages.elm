module Messages exposing
    ( Language(..)
    , Messages
    , allLanguages
    , fromFlags
    , get
    , toIso2
    )

import Data.Flags exposing (Flags)
import Html exposing (Html, div)


type Language
    = English
    | German


allLanguages : List Language
allLanguages =
    [ English
    , German
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


{-| The messages record contains all strings used in the application.
-}
type alias Messages =
    { iso2 : String
    , label : String
    , flagIcon : String
    , username : String
    , password : String
    , loginPlaceholder : String
    , passwordPlaceholder : String
    , loginButton : String
    , loginVia : String
    , loginSuccessful : String
    , noAccount : String
    , signupLink : String
    }


get : Language -> Messages
get lang =
    case lang of
        English ->
            gb

        German ->
            de


fromFlags : Flags -> Messages
fromFlags flags =
    Maybe.map fromIso2 flags.language
        |> Maybe.withDefault English
        |> get



{- for icons, see https://semantic-ui.com/elements/flag.html -}


gb : Messages
gb =
    { iso2 = "gb"
    , label = "English"
    , flagIcon = "gb uk flag"
    , username = "Username"
    , password = "Password"
    , loginPlaceholder = "Login"
    , passwordPlaceholder = "Password"
    , loginButton = "Login"
    , loginVia = "via"
    , loginSuccessful = "Login successful"
    , noAccount = "No account?"
    , signupLink = "Sign up!"
    }


de : Messages
de =
    { iso2 = "de"
    , label = "Deutsch"
    , flagIcon = "de flag"
    , username = "Benutzer"
    , password = "Passwort"
    , loginPlaceholder = "Login"
    , passwordPlaceholder = "Passwort"
    , loginButton = "Anmelden"
    , loginVia = "via"
    , loginSuccessful = "Erfolgreich angemeldet"
    , noAccount = "Kein Konto?"
    , signupLink = "Hier registrieren!"
    }
