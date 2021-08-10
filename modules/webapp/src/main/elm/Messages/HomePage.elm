module Messages.HomePage exposing
    ( Texts
    , de
    , fr
    , gb
    )


type alias Texts =
    { createShare : String
    , viewShares : String
    , createAlias : String
    , viewAliases : String
    , documentation : String
    , shareFilesWithOthers : String
    }


gb : Texts
gb =
    { createShare = "Create Share"
    , viewShares = "View Shares"
    , createAlias = "Create Alias"
    , viewAliases = "View Aliases"
    , documentation = "Documentation"
    , shareFilesWithOthers = "Share files with others"
    }


de : Texts
de =
    { createShare = "Neue Datei-Freigabe erstellen"
    , viewShares = "Datei-Freigaben ansehen"
    , createAlias = "Neue Alias Seite"
    , viewAliases = "Alias Seiten anzeigen"
    , documentation = "Dokumentation (Englisch)"
    , shareFilesWithOthers = "Dateien mit anderen teilen"
    }


fr : Texts
fr =
    { createShare = "Créer un partage"
    , viewShares = "Voir les partages"
    , createAlias = "Nouvelle page d'Alias"
    , viewAliases = "Pages d'Alias"
    , documentation = "Documentation"
    , shareFilesWithOthers = "Partager des fichiers"
    }
