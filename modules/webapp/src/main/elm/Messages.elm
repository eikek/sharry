module Messages exposing
    ( Account
    , Language(..)
    , Login
    , Messages
    , Register
    , allLanguages
    , fromFlags
    , get
    , toIso2
    )

import Data.Flags exposing (Flags)
import Messages.AccountForm
import Messages.AccountTable


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



-- Login page texts


type alias Login =
    { username : String
    , password : String
    , loginPlaceholder : String
    , passwordPlaceholder : String
    , loginButton : String
    , via : String
    , loginSuccessful : String
    , noAccount : String
    , signupLink : String
    }


loginGB : Login
loginGB =
    { username = "Username"
    , password = "Password"
    , loginPlaceholder = "Login"
    , passwordPlaceholder = "Password"
    , loginButton = "Login"
    , via = "via"
    , loginSuccessful = "Login successful"
    , noAccount = "No account?"
    , signupLink = "Sign up!"
    }



-- Register page texts


type alias Register =
    { signup : String
    , userLogin : String
    , password : String
    , passwordRepeat : String
    , invitationKey : String
    , submitButton : String
    , alreadySignedUp : String
    , signin : String
    , registrationSuccessful : String
    }


registerGB : Register
registerGB =
    { signup = "Sign up"
    , userLogin = "User Login"
    , password = "Password"
    , passwordRepeat = "Password (repeat)"
    , invitationKey = "Invitation Key"
    , submitButton = "Submit"
    , alreadySignedUp = "Already signed up?"
    , signin = "Sign in"
    , registrationSuccessful = "Registration successful."
    }



-- Account page texts


type alias Account =
    { createAccountTitle : String
    , accounts : String
    , searchPlaceholder : String
    , newAccount : String
    , accountForm : Messages.AccountForm.AccountForm
    , accountTable : Messages.AccountTable.AccountTable
    }


accountGB : Account
accountGB =
    { createAccountTitle = "Create a new internal account"
    , accounts = "Accounts"
    , searchPlaceholder = "Search…"
    , newAccount = "New Account"
    , accountForm = Messages.AccountForm.gb
    , accountTable = Messages.AccountTable.gb
    }



-- Messages


{-| The messages record contains all strings used in the application.
-}
type alias Messages =
    { iso2 : String
    , label : String
    , flagIcon : String
    , login : Login
    , register : Register
    , account : Account
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
    , login = loginGB
    , register = registerGB
    , account = accountGB
    }
