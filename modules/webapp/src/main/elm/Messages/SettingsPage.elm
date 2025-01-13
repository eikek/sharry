module Messages.SettingsPage exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
    , es
	, it
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

it : Texts
it =
    { settingsTitle = "Impostazioni"
    , changeMailHeader = "Cambia Indirizzo E-Mail"
    , newEmail = "Nuova E-Mail"
    , newEmailPlaceholder = "Indirizzo E-Mail"
    , submitEmptyMailInfo = "L'invio di un modulo vuoto elimina l'indirizzo e-mail."
    , submit = "Invia"
    , changePasswordHeader = "Cambia Password"
    , currentPassword = "Password Attuale"
    , newPassword = "Nuova Password"
    , newPasswordRepeat = "Nuova Password (Ripeti)"
    }

es : Texts
es =
    { settingsTitle = "Configuración"
    , changeMailHeader = "Cambia tu Correo Electrónico"
    , newEmail = "Nuevo Correo Electrónico"
    , newEmailPlaceholder = "Dirección de Correo Electrónico"
    , submitEmptyMailInfo = "Enviar un formulario vacío elimina la dirección de correo electrónico."
    , submit = "Enviar"
    , changePasswordHeader = "Cambiar Contraseña"
    , currentPassword = "Contraseña Actual"
    , newPassword = "Nueva Contraseña"
    , newPasswordRepeat = "Nueva Contraseña (Repetir)"
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

fr : Texts
fr =
    { settingsTitle = "Paramètres"
    , changeMailHeader = "Changer votre email"
    , newEmail = " Nouvel email"
    , newEmailPlaceholder = "Addresse email"
    , submitEmptyMailInfo = "Soumettre un formulaire vide supprime l'adresse email."
    , submit = "Envoyer"
    , changePasswordHeader = "Changer de mot de passe"
    , currentPassword = "Mot de passe actuel"
    , newPassword = "Nouveau mot de passe"
    , newPasswordRepeat = "Nouveau mot de passe (bis)"
    }


ja : Texts
ja =
    { settingsTitle = "設定"
    , changeMailHeader = "メールアドレスの変更"
    , newEmail = "新しいメールアドレス"
    , newEmailPlaceholder = "新しいメールアドレス"
    , submitEmptyMailInfo = "空のままにすると、メールアドレスを削除します。"
    , submit = "保存"
    , changePasswordHeader = "パスワードの変更"
    , currentPassword = "現在のパスワード"
    , newPassword = "新しいパスワード"
    , newPasswordRepeat = "新しいパスワード ( 確認 )"
    }


cz : Texts
cz =
    { settingsTitle = "Nastavení"
    , changeMailHeader = "Změnit E-Mail"
    , newEmail = "Nový E-Mail"
    , newEmailPlaceholder = "E-Mailová adresa"
    , submitEmptyMailInfo = "Odesláním prázdného formuláře smažete E-Mailovou adresu."
    , submit = "Odeslat"
    , changePasswordHeader = "Změnit heslo"
    , currentPassword = "Stávající heslo"
    , newPassword = "Nové heslo"
    , newPasswordRepeat = "Nové heslo (znovu)"
    }
