module Messages.ShareTable exposing
    ( Texts
    , de
    , gb
    , fr
    )


type alias Texts =
    { nameId : String
    , aliasLabel : String
    , maxViews : String
    , published : String
    , nFiles : String
    , size : String
    , created : String
    }


gb : Texts
gb =
    { nameId = "Name/Id"
    , aliasLabel = "Alias"
    , maxViews = "Max Views"
    , published = "Published"
    , nFiles = "#Files"
    , size = "Size"
    , created = "Created"
    }


de : Texts
de =
    { nameId = "Name/Id"
    , aliasLabel = "Alias"
    , maxViews = "Max. Ansichten"
    , published = "Veröffentlicht"
    , nFiles = "#Dateien"
    , size = "Größe"
    , created = "Erstellt"
    }

fr : Texts
fr =
    { nameId = "Nom/Id"
    , aliasLabel = "Alias"
    , maxViews = "Vues max."
    , published = "Publié"
    , nFiles = "#Fichiers"
    , size = "Taille"
    , created = "Créé"
    }
