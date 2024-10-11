module Messages.LoginPage exposing
    ( Texts
    , de
    , gb
    , fr
    , ja
    , cz
    , es
    )

import Messages.FixedDropdown


type alias Texts =
    { username : String
    , password : String
    , loginPlaceholder : String
    , passwordPlaceholder : String
    , loginButton : String
    , via : String
    , loginSuccessful : String
    , noAccount : String
    , signupLink : String
    , or : String
    , dropdown : Messages.FixedDropdown.Texts
    }


es : Texts
es =
    { username = "Nombre de usuario"
    , password = "Contraseña"
    , loginPlaceholder = "Usuario"
    , passwordPlaceholder = "Contraseña"
    , loginButton = "Iniciar sesión"
    , via = "vía"
    , loginSuccessful = "Inicio de sesión exitoso"
    , noAccount = "¿No tienes una cuenta?"
    , signupLink = "¡Regístrate!"
    , or = "O"
    , dropdown = Messages.FixedDropdown.es
    }


gb : Texts
gb =
    { username = "Username"
    , password = "Password"
    , loginPlaceholder = "Login"
    , passwordPlaceholder = "Password"
    , loginButton = "Login"
    , via = "via"
    , loginSuccessful = "Login successful"
    , noAccount = "No account?"
    , signupLink = "Sign up!"
    , or = "Or"
    , dropdown = Messages.FixedDropdown.gb
    }


de : Texts
de =
    { username = "Benutzer"
    , password = "Passwort"
    , loginPlaceholder = "Benutzer"
    , passwordPlaceholder = "Passwort"
    , loginButton = "Anmelden"
    , via = "via"
    , loginSuccessful = "Anmeldung erfolgreich"
    , noAccount = "Kein Konto?"
    , signupLink = "Hier registrieren!"
    , or = "Oder"
    , dropdown = Messages.FixedDropdown.de
    }

fr : Texts
fr =
    { username = "Identifiant"
    , password = "Mot de passe"
    , loginPlaceholder = "Utilisateur"
    , passwordPlaceholder = "Mot de passe"
    , loginButton = "Connexion"
    , via = "via"
    , loginSuccessful = "Identification réussie"
    , noAccount = "Pas de compte ?"
    , signupLink = "S'inscrire"
    , or = "Ou"
    , dropdown = Messages.FixedDropdown.fr
    }

ja : Texts
ja =
    { username = "ユーザー名"
    , password = "パスワード"
    , loginPlaceholder = "username"
    , passwordPlaceholder = "Password"
    , loginButton = "ログイン"
    , via = "via"
    , loginSuccessful = "ログインしました"
    , noAccount = "未登録 ?"
    , signupLink = "ユーザー登録"
    , or = "または"
    , dropdown = Messages.FixedDropdown.ja
    }

cz : Texts
cz =
    { username = "Uživatelské jméno"
    , password = "Heslo"
    , loginPlaceholder = "Uživatelské jméno"
    , passwordPlaceholder = "Heslo"
    , loginButton = "Přihlásit se"
    , via = "via"
    , loginSuccessful = "Přihlášení bylo úspěšné"
    , noAccount = "Nemáte účet?"
    , signupLink = "Zaregistrovat se"
    , or = "Nebo"
    , dropdown = Messages.FixedDropdown.cz
    }

