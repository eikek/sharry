module Messages.ShareTable exposing
    ( Texts
    , de
    , fr
    , gb
    , ja
    , cz
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


ja : Texts
ja =
    { nameId = "共有名・ID"
    , aliasLabel = "受信箱"
    , maxViews = "最大表示回数"
    , published = "公開 ?"
    , nFiles = "ファイル数"
    , size = "サイズ"
    , created = "作成日時"
    , open = "開く"
    , dateTime = Messages.DateFormat.formatDateTime Language.Japanese
    }


cz : Texts
cz =
    { nameId = "Název/ID"
    , aliasLabel = "Prostor"
    , maxViews = "Max počet zobrazení"
    , published = "Veřejné"
    , nFiles = "#Souborů"
    , size = "Velikost"
    , created = "Vytvořeno"
    , open = "Otevřít"
    , dateTime = Messages.DateFormat.formatDateTime Language.Czech
    }

