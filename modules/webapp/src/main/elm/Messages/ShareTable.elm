module Messages.ShareTable exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Language
import Messages.DateFormat


type alias Texts =
    { nameId : String
    , aliasLabel : String
    , maxViews : String
    , published : String
    , nFiles : String
    , size : String
    , created : String
    , dateTime : Int -> String
    , open : String
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
    , open = "Open"
    , dateTime = Messages.DateFormat.formatDateTime Language.English
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
    , open = "Öffnen"
    , dateTime = Messages.DateFormat.formatDateTime Language.German
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
    , open = "Ouvrir"
    , dateTime = Messages.DateFormat.formatDateTime Language.French
    }
