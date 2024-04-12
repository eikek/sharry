module Messages.AccountTable exposing
    ( Texts
    , de
    , fr
    , gb
    , ja
    , cz
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


ja : Texts
ja =
    { login = "ログイン"
    , source = "ソース"
    , state = "状態"
    , nrShares = "共有数"
    , admin = "管理者"
    , nrLogins = "ログイン回数"
    , lastLogin = "最終ログイン"
    , created = "作成日時"
    , edit = "編集"
    , dateTime = formatDateTime Language.Japanese
    }

cz : Texts
cz  =
    { login = "Uživatelské jméno"
    , source = "Zdroj"
    , state = "Stav"
    , nrShares = "#Sdílení"
    , admin = "Admin"
    , nrLogins = "#Přihlášení"
    , lastLogin = "Poslední přihlášení"
    , created = "Založeno"
    , edit = "Editovat"
    , dateTime = formatDateTime Language.Czech
    }
