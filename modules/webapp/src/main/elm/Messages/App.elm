module Messages.App exposing
    ( Texts
    , de
    , gb
    )


type alias Texts =
    { home : String
    , shares : String
    , aliases : String
    , accounts : String
    , settings : String
    , newInvites : String
    , logout : String -> String
    , login : String
    , register : String
    }


gb : Texts
gb =
    { home = "Home"
    , shares = "Shares"
    , aliases = "Aliases"
    , accounts = "Accounts"
    , settings = "Settings"
    , newInvites = "New Invites"
    , logout = \user -> "Logout (" ++ user ++ ")"
    , login = "Login"
    , register = "Register"
    }


de : Texts
de =
    { home = "Home"
    , shares = "Shares"
    , aliases = "Aliase"
    , accounts = "Konten"
    , settings = "Einstellungen"
    , newInvites = "Einladungen"
    , logout = \user -> "Abmelden (" ++ user ++ ")"
    , login = "Anmelden"
    , register = "Registrieren"
    }
