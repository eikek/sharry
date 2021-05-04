module Messages.AccountForm exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Messages.FixedDropdown
import Messages.YesNoDimmer


type alias Texts =
    { id : String
    , login : String
    , state : String
    , admin : String
    , password : String
    , submit : String
    , back : String
    , delete : String
    , yesNo : Messages.YesNoDimmer.Texts
    , dropdown : Messages.FixedDropdown.Texts
    }


gb : Texts
gb =
    { id = "Id"
    , login = "Login"
    , state = "State"
    , admin = "Admin"
    , password = "Password"
    , submit = "Submit"
    , back = "Back"
    , delete = "Delete"
    , yesNo = Messages.YesNoDimmer.gb
    , dropdown = Messages.FixedDropdown.gb
    }


de : Texts
de =
    { id = "Id"
    , login = "Benutzer"
    , state = "Status"
    , admin = "Admin"
    , password = "Passwort"
    , submit = "Speichern"
    , back = "Zurück"
    , delete = "Löschen"
    , yesNo = Messages.YesNoDimmer.de
    , dropdown = Messages.FixedDropdown.de
    }


fr : Texts
fr =
    { id = "Id"
    , login = "Identifiant"
    , state = "État"
    , admin = "Admin"
    , password = "Mot de passe"
    , submit = "Envoyer"
    , back = "Retour"
    , delete = "Supprimer"
    , yesNo = Messages.YesNoDimmer.gb
    , dropdown = Messages.FixedDropdown.fr
    }
