module Messages.AccountTable exposing
    ( Texts
    , de
    , gb
    , fr
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


de : Texts
de =
    { login = "Benutzer"
    , source = "Quelle"
    , state = "Status"
    , nrShares = "#Freigaben"
    , admin = "Admin"
    , nrLogins = "#Anmeldungen"
    , lastLogin = "Letzte Anmeldung"
    , created = "Erstellt"
    }

fr : Texts
fr =
    { login = "Identifiant"
    , source = "Source"
    , state = "État"
    , nrShares = "#Partages"
    , admin = "Admin"
    , nrLogins = "#Identifiants"
    , lastLogin = "Dernière connexion"
    , created = "Créé"
    }
