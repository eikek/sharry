module Messages.App exposing
    ( Texts
    , de
    , fr
    , gb
    , ja
    , cz
    , es
    , it
    )


type alias Texts =
    { home : String
    , shares : String
    , aliases : String
    , accounts : String
    , settings : String
    , newInvites : String
    , logout : String -> String
    , login : String
    , register : String
    , lightDark : String
    , logoutSharry : String
    , logoutOAuth : String
    }

it : Texts
it =
    { home = "Home"
    , shares = "Condivisione"
    , aliases = "Aliases"
    , accounts = "Accounts"
    , settings = "Impostazioni"
    , newInvites = "Nuovi inviti"
    , logout = \user -> "Esci (" ++ user ++ ")"
    , login = "Accedi"
    , register = "Registrazione"
    , lightDark = "Chiaro/Scuro"
    , logoutSharry = "Esci da Sharry"
    , logoutOAuth = "Esci dal fornitore di autenticazione"
    }

es : Texts
es =
    { home = "Inicio"
    , shares = "Compartidos"
    , aliases = "Aliases"
    , accounts = "Cuentas"
    , settings = "Configuración"
    , newInvites = "Nuevas Invitaciones"
    , logout = \user -> "Cerrar sesión (" ++ user ++ ")"
    , login = "Iniciar sesión"
    , register = "Registrarse"
    , lightDark = "Claro/Oscuro"
    , logoutSharry = "Cerrar sesión en Sharry"
    , logoutOAuth = "Cerrar sesión en tu proveedor de autenticación"
    }


gb : Texts
gb =
    { home = "Home"
    , shares = "Shares"
    , aliases = "Aliases"
    , accounts = "Accounts"
    , settings = "Settings"
    , newInvites = "New Invites"
    , logout = \user -> "Logout (" ++ user ++ ")"
    , login = "Login"
    , register = "Register"
    , lightDark = "Light/Dark"
    , logoutSharry = "Logout from Sharry"
    , logoutOAuth = "Logout at your authentication provider"
    }


de : Texts
de =
    { home = "Home"
    , shares = "Freigaben"
    , aliases = "Aliase"
    , accounts = "Konten"
    , settings = "Einstellungen"
    , newInvites = "Einladungen"
    , logout = \user -> "Abmelden (" ++ user ++ ")"
    , login = "Anmelden"
    , register = "Registrieren"
    , lightDark = "Hell/Dunkel"
    , logoutSharry = "Von Sharry abmelden"
    , logoutOAuth = "Abmelden nur über den Authentifizierungs-Provider möglich"
    }


fr : Texts
fr =
    { home = "Accueil"
    , shares = "Partages"
    , aliases = "Alias"
    , accounts = "Comptes"
    , settings = "Paramètres"
    , newInvites = "Invitations"
    , logout = \user -> "Déconnexion (" ++ user ++ ")"
    , login = "Connexion"
    , register = "Inscription"
    , lightDark = gb.lightDark
    , logoutSharry = "Déconnexion de Sharry"
    , logoutOAuth = "Déconnexion de votre fournisseur d'authentification"
    }


ja : Texts
ja =
    { home = "ホーム"
    , shares = "共有"
    , aliases = "受信箱"
    , accounts = "アカウント"
    , settings = "設定"
    , newInvites = "招待"
    , logout = \user -> "ログアウト (" ++ user ++ ")"
    , login = "ログイン"
    , register = "登録"
    , lightDark = "ライト / ダーク"
    , logoutSharry = "ログアウト"
    , logoutOAuth = "認証プロバイダーからログアウト"
    }

cz : Texts
cz =
    { home = "Domů"
    , shares = "Sdílené soubory"
    , aliases = "Prostory pro sdílení"
    , accounts = "Účty"
    , settings = "Nastavení"
    , newInvites = "Pozvánky"
    , logout = \user -> "Odhlásit (" ++ user ++ ")"
    , login = "Přihlášení"
    , register = "Registrace"
    , lightDark = "Světlý/Tmavý režim"
    , logoutSharry = "Odhlásit"
    , logoutOAuth = "Odhlásit u poskytovatele ověření"
    }
