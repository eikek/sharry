module Messages.AccountTable exposing
    ( Texts
    , gb
    )

-- AccountTable component texts


type alias Texts =
    { login : String
    , source : String
    , state : String
    , nrShares : String
    , admin : String
    , nrLogins : String
    , lastLogin : String
    , created : String
    }


gb : Texts
gb =
    { login = "Login"
    , source = "Source"
    , state = "State"
    , nrShares = "#Shares"
    , admin = "Admin"
    , nrLogins = "#Logins"
    , lastLogin = "Last Login"
    , created = "Created"
    }
