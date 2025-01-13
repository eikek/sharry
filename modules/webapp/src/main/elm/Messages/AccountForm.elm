module Messages.AccountForm exposing
    ( Texts
    , de
    , fr
    , gb
    , ja
    , cz
    , es
	, it
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
    , email : String
    , yesNo : Messages.YesNoDimmer.Texts
    , dropdown : Messages.FixedDropdown.Texts
    }

it : Texts
it =
    { id = "Id"
    , login = "Accedi"
    , state = "Stato"
    , admin = "Amministratore"
    , password = "Password"
    , submit = "Invia"
    , back = "Indietro"
    , delete = "Elimina"
    , email = "E-Mail"
    , yesNo = Messages.YesNoDimmer.it
    , dropdown = Messages.FixedDropdown.it
    }

es : Texts
es =
    { id = "Id"
    , login = "Iniciar sesión"
    , state = "Estado"
    , admin = "Administrador"
    , password = "Contraseña"
    , submit = "Enviar"
    , back = "Atrás"
    , delete = "Eliminar"
    , email = "Correo Electrónico"
    , yesNo = Messages.YesNoDimmer.es
    , dropdown = Messages.FixedDropdown.es
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
    , email = "E-Mail"
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
    , email = "E-Mail"
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
    , email = "e-mail"
    , yesNo = Messages.YesNoDimmer.gb
    , dropdown = Messages.FixedDropdown.fr
    }


ja : Texts
ja =
    { id = "ID"
    , login = "ログイン"
    , state = "状態"
    , admin = "管理者"
    , password = "パスワード"
    , submit = "保存"
    , back = "戻る"
    , delete = "削除"
    , email = "メール"
    , yesNo = Messages.YesNoDimmer.ja
    , dropdown = Messages.FixedDropdown.ja
    }

cz : Texts
cz =
    { id = "Id"
    , login = "Uživatelské jméno"
    , state = "Status"
    , admin = "Admin"
    , password = "Heslo"
    , submit = "Odeslat"
    , back = "Zpět"
    , delete = "Smazat"
    , email = "E-Mail"
    , yesNo = Messages.YesNoDimmer.cz
    , dropdown = Messages.FixedDropdown.cz
    }

