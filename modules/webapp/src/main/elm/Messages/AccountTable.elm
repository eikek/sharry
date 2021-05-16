module Messages.AccountTable exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Language
import Messages.DateFormat exposing (formatDateTime)



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
    , edit : String
    , dateTime : Int -> String
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
    , edit = "Edit"
    , dateTime = formatDateTime Language.English
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
    , edit = "Editieren"
    , dateTime = formatDateTime Language.German
    }


fr : Texts
fr =
    { login = "Identifiant"
    , source = "Source"
    , state = "État"
    , nrShares = "#Partages"
    , admin = "Admin"
    , nrLogins = "#Connexions"
    , lastLogin = "Dernière connexion"
    , created = "Créé"
    , edit = "Éditer"
    , dateTime = formatDateTime Language.French
    }
