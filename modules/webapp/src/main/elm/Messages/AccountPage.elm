module Messages.AccountPage exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
    , es
	, it
    )

import Messages.AccountForm
import Messages.AccountTable


type alias Texts =
    { createAccountTitle : String
    , accounts : String
    , searchPlaceholder : String
    , newAccount : String
    , accountForm : Messages.AccountForm.Texts
    , accountTable : Messages.AccountTable.Texts
    }

it : Texts
it =
    { createAccountTitle = "Crea nuovo utente locale"
    , accounts = "Utenti"
    , searchPlaceholder = "Cerca…"
    , newAccount = "Nuovo Utente"
    , accountForm = Messages.AccountForm.it
    , accountTable = Messages.AccountTable.it
    }

es : Texts
es =
    { createAccountTitle = "Crear una nueva cuenta interna"
    , accounts = "Cuentas"
    , searchPlaceholder = "Buscar…"
    , newAccount = "Nueva Cuenta"
    , accountForm = Messages.AccountForm.es
    , accountTable = Messages.AccountTable.es
    }


gb : Texts
gb =
    { createAccountTitle = "Create a new internal account"
    , accounts = "Accounts"
    , searchPlaceholder = "Search…"
    , newAccount = "New Account"
    , accountForm = Messages.AccountForm.gb
    , accountTable = Messages.AccountTable.gb
    }


de : Texts
de =
    { createAccountTitle = "Neues internes Konto erstellen"
    , accounts = "Konten"
    , searchPlaceholder = "Suche…"
    , newAccount = "Neues Konto"
    , accountForm = Messages.AccountForm.de
    , accountTable = Messages.AccountTable.de
    }

fr : Texts
fr =
    { createAccountTitle = "Créer un nouveau compte local"
    , accounts = "Comptes"
    , searchPlaceholder = "Recherche…"
    , newAccount = "Nouveau compte"
    , accountForm = Messages.AccountForm.fr
    , accountTable = Messages.AccountTable.fr
    }


ja : Texts
ja =
    { createAccountTitle = "アカウントの新規作成"
    , accounts = "アカウント"
    , searchPlaceholder = "検索…"
    , newAccount = "アカウントの新規作成"
    , accountForm = Messages.AccountForm.ja
    , accountTable = Messages.AccountTable.ja
    }

cz : Texts
cz =
    { createAccountTitle = "Vytvořit interní účet"
    , accounts = "Účty"
    , searchPlaceholder = "Hledat…"
    , newAccount = "Nový účet"
    , accountForm = Messages.AccountForm.cz
    , accountTable = Messages.AccountTable.cz
    }


