module Messages.ShareTable exposing
    ( Texts
    , applyZone
    , de
    , fr
    , gb
    , ja
    , cz
    , es
    , it
    , br
    )

import Language exposing (Language)
import Messages.DateFormat
import Time


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

it : Texts
it =
    { nameId = "Nome/Id"
    , aliasLabel = "Alias"
    , maxViews = "Visualizzazioni Massime"
    , published = "Pubblicazione"
    , nFiles = "#Files"
    , size = "Dimensione"
    , created = "Creazione"
    , open = "Apri"
    , dateTime = Messages.DateFormat.formatDateTime Language.Italian Time.utc
    }

es : Texts
es =
    { nameId = "Nombre/Id"
    , aliasLabel = "Alias"
    , maxViews = "Vistas Máximas"
    , published = "Publicado"
    , nFiles = "#Archivos"
    , size = "Tamaño"
    , created = "Creado"
    , open = "Abrir"
    , dateTime = Messages.DateFormat.formatDateTime Language.Spanish Time.utc
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
    , dateTime = Messages.DateFormat.formatDateTime Language.English Time.utc
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
    , dateTime = Messages.DateFormat.formatDateTime Language.German Time.utc
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
    , dateTime = Messages.DateFormat.formatDateTime Language.French Time.utc
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
    , dateTime = Messages.DateFormat.formatDateTime Language.Japanese Time.utc
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
    , dateTime = Messages.DateFormat.formatDateTime Language.Czech Time.utc
    }

br : Texts
br =
    { nameId = "Nome/Id"
    , aliasLabel = "Alias"
    , maxViews = "Máx. Visualizações"
    , published = "Publicado"
    , nFiles = "#Arquivos"
    , size = "Tamanho"
    , created = "Criado"
    , open = "Abrir"
    , dateTime = Messages.DateFormat.formatDateTime Language.Portuguese Time.utc
    }


applyZone : Time.Zone -> Language -> Texts -> Texts
applyZone zone lang texts =
    { texts | dateTime = Messages.DateFormat.formatDateTime lang zone }

