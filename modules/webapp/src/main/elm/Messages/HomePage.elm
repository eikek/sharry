module Messages.HomePage exposing
    ( Texts
    , de
    , fr
    , gb
    , ja
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

ja : Texts
ja =
    { createShare = "共有の新規作成"
    , viewShares = "共有を表示"
    , createAlias = "受信箱の新規作成"
    , viewAliases = "受信箱を表示"
    , documentation = "ヘルプ"
    , shareFilesWithOthers = "ファイルの共有 ( 配布 ) と受信"
    }
