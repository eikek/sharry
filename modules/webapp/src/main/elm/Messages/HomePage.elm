module Messages.HomePage exposing
    ( Texts
    , de
    , gb
    , fr
    )


type alias Texts =
    { createShare : String
    , viewShares : String
    , documentation : String
    , shareFilesWithOthers : String
    }


gb : Texts
gb =
    { createShare = "Create Share"
    , viewShares = "View Shares"
    , documentation = "Documentation"
    , shareFilesWithOthers = "Share files with others"
    }


de : Texts
de =
    { createShare = "Neue Datei-Freigabe erstellen"
    , viewShares = "Datei-Freigaben ansehen"
    , documentation = "Dokumentation (Englisch)"
    , shareFilesWithOthers = "Dateien mit anderen teilen"
    }

fr : Texts
fr =
    { createShare = "Créer un partage"
    , viewShares = "Voir les partages"
    , documentation = "Documentation"
    , shareFilesWithOthers = "Partager des fichiers"
    }
