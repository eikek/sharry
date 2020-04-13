module Messages.SettingsPage exposing
    ( Texts
    , de
    , gb
    )


type alias Texts =
    { settingsTitle : String
    , changeMailHeader : String
    , newEmail : String
    , newEmailPlaceholder : String
    , submitEmptyMailInfo : String
    , submit : String
    , changePasswordHeader : String
    , currentPassword : String
    , newPassword : String
    , newPasswordRepeat : String
    }


gb : Texts
gb =
    { settingsTitle = "Settings"
    , changeMailHeader = "Change your E-Mail"
    , newEmail = "New E-Mail"
    , newEmailPlaceholder = "E-Mail address"
    , submitEmptyMailInfo = "Submitting an empty form deletes the E-Mail address."
    , submit = "Submit"
    , changePasswordHeader = "Change Password"
    , currentPassword = "Current Password"
    , newPassword = "New Password"
    , newPasswordRepeat = "New Password (Repeat)"
    }


de : Texts
de =
    { settingsTitle = "Einstellungen"
    , changeMailHeader = "E-Mail ändern"
    , newEmail = "Neue E-Mail"
    , newEmailPlaceholder = "E-Mail Addresse"
    , submitEmptyMailInfo = "Abschicken eines leeren Formulars löscht die E-Mail Addresse."
    , submit = "Speichern"
    , changePasswordHeader = "Passwort ändern"
    , currentPassword = "Aktuelles Passwort"
    , newPassword = "Neues Passwort"
    , newPasswordRepeat = "Neues Passwort (Wiederholung)"
    }
