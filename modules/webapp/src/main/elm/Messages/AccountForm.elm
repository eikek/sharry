module Messages.AccountForm exposing
    ( Texts
    , de
    , gb
    )

import Messages.FixedDropdown


type alias Texts =
    { id : String
    , login : String
    , state : String
    , admin : String
    , password : String
    , submit : String
    , back : String
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
    , dropdown = Messages.FixedDropdown.de
    }
