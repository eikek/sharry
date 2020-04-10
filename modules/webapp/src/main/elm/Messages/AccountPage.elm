module Messages.AccountPage exposing
    ( Texts
    , gb
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
