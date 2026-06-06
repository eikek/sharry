module Messages.AccountTable exposing
    ( Texts
    , applyZone
    , de
    , fr
    , gb
    , ja
    , cz
    , es
    , it
    )

import Language exposing (Language)
import Messages.DateFormat exposing (formatDateTime)
import Time



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

it : Texts
it =
    { login = "Accedi"
    , source = "Sorgente"
    , state = "Stato"
    , nrShares = "#Condivisioni"
    , admin = "Amministratore"
    , nrLogins = "#Accessi"
    , lastLogin = "Ultimo Accesso"
    , created = "Creazione"
    , edit = "Modifica"
    , dateTime = formatDateTime Language.Italian Time.utc
    }

es : Texts
es =
    { login = "Iniciar sesión"
    , source = "Fuente"
    , state = "Estado"
    , nrShares = "#Compartidos"
    , admin = "Administrador"
    , nrLogins = "#Inicios de sesión"
    , lastLogin = "Último inicio de sesión"
    , created = "Creado"
    , edit = "Editar"
    , dateTime = formatDateTime Language.Spanish Time.utc
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
    , dateTime = formatDateTime Language.English Time.utc
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
    , dateTime = formatDateTime Language.German Time.utc
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
    , dateTime = formatDateTime Language.French Time.utc
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
    , dateTime = formatDateTime Language.Japanese Time.utc
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
    , dateTime = formatDateTime Language.Czech Time.utc
    }


applyZone : Time.Zone -> Language -> Texts -> Texts
applyZone zone lang texts =
    { texts | dateTime = formatDateTime lang zone }
