module Messages.App exposing
    ( Texts
    , de
    , fr
    , gb
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
