module Messages.AccountPage exposing
    ( Texts
    , de
    , gb
    , fr
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
