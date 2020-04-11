module Messages.LoginPage exposing
    ( Texts
    , gb
    )

import Messages.FixedDropdown


type alias Texts =
    { username : String
    , password : String
    , loginPlaceholder : String
    , passwordPlaceholder : String
    , loginButton : String
    , via : String
    , loginSuccessful : String
    , noAccount : String
    , signupLink : String
    , dropdown : Messages.FixedDropdown.Texts
    }


gb : Texts
gb =
    { username = "Username"
    , password = "Password"
    , loginPlaceholder = "Login"
    , passwordPlaceholder = "Password"
    , loginButton = "Login"
    , via = "via"
    , loginSuccessful = "Login successful"
    , noAccount = "No account?"
    , signupLink = "Sign up!"
    , dropdown = Messages.FixedDropdown.gb
    }
