module Messages.SettingsPage exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
    , es
    , it
    , br
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
    , timezoneHeader : String
    , timezoneAutoLabel : String
    , timezoneAutoHint : String
    , timezoneManualLabel : String
    , timezoneResetButton : String
    , timezoneInputPlaceholder : String
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
    , timezoneHeader = "Fuso Orario"
    , timezoneAutoLabel = "Automatico (dal browser)"
    , timezoneAutoHint = "Il fuso orario viene rilevato automaticamente dal browser."
    , timezoneManualLabel = "Fuso orario attuale:"
    , timezoneResetButton = "Ripristina automatico"
    , timezoneInputPlaceholder = "Es. Europe/Rome"
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
    , timezoneHeader = "Zona Horaria"
    , timezoneAutoLabel = "Automático (desde el navegador)"
    , timezoneAutoHint = "La zona horaria se detecta automáticamente desde el navegador."
    , timezoneManualLabel = "Zona horaria actual:"
    , timezoneResetButton = "Restablecer automático"
    , timezoneInputPlaceholder = "Ej. Europe/Madrid"
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
    , timezoneHeader = "Timezone"
    , timezoneAutoLabel = "Automatic (from browser)"
    , timezoneAutoHint = "The timezone is automatically detected from your browser."
    , timezoneManualLabel = "Current timezone:"
    , timezoneResetButton = "Reset to automatic"
    , timezoneInputPlaceholder = "E.g. Europe/London"
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
    , timezoneHeader = "Zeitzone"
    , timezoneAutoLabel = "Automatisch (vom Browser)"
    , timezoneAutoHint = "Die Zeitzone wird automatisch vom Browser erkannt."
    , timezoneManualLabel = "Aktuelle Zeitzone:"
    , timezoneResetButton = "Auf automatisch zurücksetzen"
    , timezoneInputPlaceholder = "Z.B. Europe/Berlin"
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
    , timezoneHeader = "Fuseau horaire"
    , timezoneAutoLabel = "Automatique (depuis le navigateur)"
    , timezoneAutoHint = "Le fuseau horaire est automatiquement détecté depuis votre navigateur."
    , timezoneManualLabel = "Fuseau horaire actuel :"
    , timezoneResetButton = "Revenir à l'automatique"
    , timezoneInputPlaceholder = "Ex. Europe/Paris"
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
    , timezoneHeader = "タイムゾーン"
    , timezoneAutoLabel = "自動（ブラウザから）"
    , timezoneAutoHint = "タイムゾーンはブラウザから自動的に検出されます。"
    , timezoneManualLabel = "現在のタイムゾーン："
    , timezoneResetButton = "自動に戻す"
    , timezoneInputPlaceholder = "例: Asia/Tokyo"
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
    , timezoneHeader = "Časové pásmo"
    , timezoneAutoLabel = "Automaticky (z prohlížeče)"
    , timezoneAutoHint = "Časové pásmo je automaticky detekováno z prohlížeče."
    , timezoneManualLabel = "Aktuální časové pásmo:"
    , timezoneResetButton = "Obnovit automatické"
    , timezoneInputPlaceholder = "Např. Europe/Prague"
    }

br : Texts
br =
    { settingsTitle = "Configurações"
    , changeMailHeader = "Alterar seu E-Mail"
    , newEmail = "Novo E-Mail"
    , newEmailPlaceholder = "Endereço de E-Mail"
    , submitEmptyMailInfo = "Enviar um formulário vazio exclui o endereço de e-mail."
    , submit = "Enviar"
    , changePasswordHeader = "Alterar Senha"
    , currentPassword = "Senha Atual"
    , newPassword = "Nova Senha"
    , newPasswordRepeat = "Nova Senha (Repetir)"
    , timezoneHeader = "Fuso Horário"
    , timezoneAutoLabel = "Automático (do navegador)"
    , timezoneAutoHint = "O fuso horário é detectado automaticamente pelo navegador."
    , timezoneManualLabel = "Fuso horário atual:"
    , timezoneResetButton = "Restaurar automático"
    , timezoneInputPlaceholder = "Ex. America/Sao_Paulo"
    }
